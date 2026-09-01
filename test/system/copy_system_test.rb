# frozen_string_literal: true

require "system_test_helper"
load_component "input", "input_component.rb.tt"
load_component "button", "button_component.rb.tt"
load_component "copy", "copy_component.rb.tt"

COPY_URL = "https://example.test/invitations/abc123/accept"

# A 60s duration keeps [data-state=copied]/[data-state=failed] from self-expiring mid-assertion
# on a loaded machine — every test except the two that specifically exercise the timer wants
# the feedback state to sit still. Those two use copy/default_short below, at the real 2000ms.
BrowserHarness.scenario("copy/default", controllers: %w[copy]) do
  view = ActionController::Base.new.view_context
  UI::CopyComponent.new(value: COPY_URL, label: "Invitation link",
    data: {copy_duration_value: 60_000}).render_in(view)
end

BrowserHarness.scenario("copy/default_short", controllers: %w[copy]) do
  view = ActionController::Base.new.view_context
  UI::CopyComponent.new(value: COPY_URL, label: "Invitation link").render_in(view)
end

BrowserHarness.scenario("copy/two_on_one_page", controllers: %w[copy]) do
  view = ActionController::Base.new.view_context
  UI::CopyComponent.new(value: "first", label: "First link", id: "copy-a",
    data: {copy_duration_value: 60_000}).render_in(view) +
    UI::CopyComponent.new(value: "second", label: "Second link", id: "copy-b",
      data: {copy_duration_value: 60_000}).render_in(view)
end

# The whole contract is runtime: what the clipboard receives, what each region says and
# when, that the visible text never changes, and that a failure never claims success.
# navigator.clipboard is stubbed so the test proves OUR contract, not Chrome's permission
# model (which is unverified headless and needs none of this).
class CopySystemTest < BrowserTestCase
  STUB_OK = <<~JS
    window.__copied = []
    window.__events = []
    window.addEventListener("copy:copied", (e) => window.__events.push(["copied", e.detail.value]))
    window.addEventListener("copy:failed", (e) => window.__events.push(["failed", e.detail.value]))
    Object.defineProperty(navigator, "clipboard", {
      value: { writeText: (text) => { window.__copied.push(text); return Promise.resolve() } },
      configurable: true
    })
  JS

  STUB_REJECT = <<~JS
    window.__events = []
    window.addEventListener("copy:failed", (e) => window.__events.push(["failed", e.detail.value]))
    Object.defineProperty(navigator, "clipboard", {
      value: { writeText: () => Promise.reject(new DOMException("denied", "NotAllowedError")) },
      configurable: true
    })
  JS

  STUB_ABSENT = %(Object.defineProperty(navigator, "clipboard", { value: undefined, configurable: true }))

  COPIED = "Copied Invitation link to the clipboard"
  FAILED = "Couldn't copy automatically. Invitation link is selected — use your browser or device copy command."

  # Named open_scenario, not open: a bare `open` shadows Kernel#open and trips
  # Security/Open (matches the open_scenario/open_menu naming already used by the
  # other system tests in this suite).
  def open_scenario(name = "default", stub: STUB_OK)
    visit_scenario("copy/#{name}")
    page.execute_script(stub)
  end

  def trigger = find("button[data-action='copy#copy']")
  def status_text = find("[data-copy-target=status]", visible: :all).text(:all).strip
  def error_text = find("[data-copy-target=error]", visible: :all).text(:all).strip

  def test_click_writes_the_value_and_confirms_in_the_status_region_only
    open_scenario
    trigger.click

    assert_selector "[data-controller=copy][data-state=copied]"
    assert_equal [COPY_URL], page.evaluate_script("window.__copied")
    assert_equal COPIED, status_text
    assert_equal "", error_text
    assert_equal [["copied", COPY_URL]], page.evaluate_script("window.__events")
  end

  # Label-in-name: the visible word stays "Copy" through the whole feedback window.
  def test_the_visible_button_text_never_changes
    open_scenario
    trigger.click

    assert_selector "[data-controller=copy][data-state=copied]"
    assert_equal "Copy", trigger.text.strip
    assert_selector "button[aria-label='Copy Invitation link']"
  end

  def test_the_icon_reverts_on_the_timer_but_the_status_text_persists
    open_scenario("default_short")
    trigger.click

    assert_selector "[data-controller=copy][data-state=copied]"
    assert_selector "svg[data-copy-target=successIcon]:not([hidden])", visible: :all
    assert_selector "[data-controller=copy][data-state=idle]", wait: 4
    assert_selector "svg[data-copy-target=copyIcon]:not([hidden])", visible: :all
    assert_equal COPIED, status_text
  end

  # Clear-on-press: the second announcement is a fresh "" → text mutation, never a
  # same-text rewrite assistive technology might de-duplicate.
  def test_a_second_copy_clears_the_region_before_writing_it_again
    open_scenario("default_short")
    page.execute_script(<<~JS)
      window.__writes = []
      const node = document.querySelector("[data-copy-target=status]")
      new MutationObserver(() => window.__writes.push(node.textContent))
        .observe(node, { childList: true, characterData: true, subtree: true })
    JS

    2.times do
      trigger.click

      assert_selector "[data-controller=copy][data-state=copied]"
      assert_selector "[data-controller=copy][data-state=idle]", wait: 4
    end

    # First press: the region was already empty, so the only mutation is the write.
    # Second press: the clear is a real mutation, then the write.
    assert_equal [COPIED, "", COPIED], page.evaluate_script("window.__writes")
  end

  # The empty-value/no-clipboard failure paths throw synchronously, with no await between
  # the start-of-press clear and the failure write — without a yield in between, the two
  # land in the same mutation batch and a second failure reads as a same-text rewrite.
  def test_a_second_failure_is_its_own_mutation_too
    open_scenario("default_short", stub: STUB_ABSENT)
    page.execute_script(<<~JS)
      window.__writes = []
      const node = document.querySelector("[data-copy-target=error]")
      new MutationObserver(() => window.__writes.push(node.textContent))
        .observe(node, { childList: true, characterData: true, subtree: true })
    JS

    trigger.click

    assert_selector "[data-controller=copy][data-state=failed]"
    assert_selector "[data-controller=copy][data-state=idle]", wait: 4

    trigger.click

    assert_selector "[data-controller=copy][data-state=failed]"

    assert_equal [FAILED, "", FAILED], page.evaluate_script("window.__writes")
  end

  def test_a_rejected_write_selects_the_value_and_announces_failure_assertively
    open_scenario(stub: STUB_REJECT)
    trigger.click

    assert_selector "[data-controller=copy][data-state=failed]"
    assert_equal "", status_text
    assert_equal FAILED, error_text
    assert_equal [["failed", COPY_URL]], page.evaluate_script("window.__events")
    assert page.evaluate_script(<<~JS), "the value should be selected end to end"
      (() => { const i = document.querySelector("[data-copy-target=source]");
               return i.selectionStart === 0 && i.selectionEnd === i.value.length })()
    JS
    assert_equal "Copy", trigger.text.strip
  end

  # Over a LAN IP navigator.clipboard is undefined (secure-context only): same honest path.
  def test_a_missing_clipboard_api_takes_the_failure_path
    open_scenario(stub: STUB_ABSENT)
    trigger.click

    assert_selector "[data-controller=copy][data-state=failed]"
    assert_equal "", status_text
    assert_equal FAILED, error_text
  end

  def test_an_empty_value_is_a_failure_not_a_silent_success
    open_scenario
    page.execute_script(%(document.querySelector("[data-copy-target=source]").value = ""))
    trigger.click

    assert_selector "[data-controller=copy][data-state=failed]"
    assert_equal [], page.evaluate_script("window.__copied")
  end

  def test_two_instances_are_independent
    open_scenario("two_on_one_page")
    first, second = all("[data-controller=copy]")

    first.find("button").click

    assert_selector "[data-controller=copy][data-state=copied]", count: 1
    assert_equal "Copied First link to the clipboard", first.find("[data-copy-target=status]", visible: :all).text(:all).strip
    assert_equal "", second.find("[data-copy-target=status]", visible: :all).text(:all).strip

    second.find("button").click

    assert_equal "Copied Second link to the clipboard", second.find("[data-copy-target=status]", visible: :all).text(:all).strip
    assert_equal "Copied First link to the clipboard", first.find("[data-copy-target=status]", visible: :all).text(:all).strip
  end

  # Turbo snapshots the page with cloneNode(true) just before rendering the next one;
  # the listener resets before the clone, and connect() resets after a restore.
  def test_turbo_before_cache_and_reconnect_both_reset_mid_feedback_state
    open_scenario
    trigger.click

    assert_selector "[data-controller=copy][data-state=copied]"

    page.execute_script(%(document.dispatchEvent(new Event("turbo:before-cache"))))

    assert_selector "[data-controller=copy][data-state=idle]"
    assert_equal "", status_text

    page.execute_script(<<~JS)
      const el = document.querySelector("[data-controller=copy]")
      el.dataset.state = "copied"
      el.querySelector("[data-copy-target=status]").textContent = "stale"
      const parent = el.parentNode
      parent.removeChild(el)
      parent.appendChild(el)
    JS

    assert_selector "[data-controller=copy][data-state=idle]"
    assert_equal "", status_text
  end

  def test_no_stimulus_errors_and_structural_axe_clean
    open_scenario
    trigger.click

    assert_selector "[data-controller=copy][data-state=copied]"

    assert_no_stimulus_errors
    assert_axe_clean
  end
end
