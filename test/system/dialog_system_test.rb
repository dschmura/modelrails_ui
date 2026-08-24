# frozen_string_literal: true

require "system_test_helper"
require "securerandom"
load_component "dialog", "modal_chrome.rb.tt"
load_component "dialog", "dialog_component.rb.tt"

# Two dialogs, the second opened from inside the first — the ordinary reason to stack.
BrowserHarness.scenario("dialog/stacked", controllers: %w[modal]) do
  view = ActionController::Base.new.view_context
  inner = UI::DialogComponent.new(title: "Discard changes?", id: "inner-dialog").render_in(view) do |c|
    c.with_trigger { "Discard" }
    view.tag.p("The confirm sits above the form it was opened from.")
  end
  UI::DialogComponent.new(title: "Edit project", id: "outer-dialog").render_in(view) do |c|
    c.with_trigger { "Open form" }
    inner
  end
end

# `modal_controller` warned "Stacked modals are not supported" and then called showModal()
# anyway. The browser has always supported it; these hold the behaviour the warning was
# wrong about. None of it is visible to the render lane.
class DialogSystemTest < BrowserTestCase
  def setup
    super
    visit_scenario("dialog/stacked")
    # Trigger slots render inside a span carrying the open action, not a button. The
    # inner trigger is scoped to the dialog so it is not confused with the outer one.
    find("[data-action='click->modal#open']", match: :first).click
    find("dialog[open]") # blocks until it opens; not an assertion in a lifecycle hook
    within("dialog[open]") { find("[data-action='click->modal#open']").click }
  end

  def open_dialogs = page.all("dialog[open]", visible: :all).length

  def test_the_second_dialog_opens_above_the_first
    assert_equal 2, open_dialogs
  end

  def test_focus_moves_into_the_topmost_dialog
    inner = page.evaluate_script(<<~JS)
      (() => {
        const dialogs = [...document.querySelectorAll("dialog[open]")];
        const top = dialogs[dialogs.length - 1];
        return top.contains(document.activeElement);
      })()
    JS

    assert inner
  end

  def test_escape_closes_only_the_topmost
    press(:Escape)

    assert_selector "dialog[open]", count: 1, visible: :all
  end

  def test_a_second_escape_closes_the_one_beneath
    press(:Escape)

    assert_selector "dialog[open]", count: 1, visible: :all

    press(:Escape)

    assert_no_selector "dialog[open]", visible: :all
    assert_no_stimulus_errors
  end
end

# One dialog whose opener can be detached while it is open — the list-page
# reality (a Turbo Stream removes the row whose button opened the confirm).
BrowserHarness.scenario("dialog/focus_restore", controllers: %w[modal]) do
  view = ActionController::Base.new.view_context
  before = view.tag.button("Before", id: "before-btn", type: "button")
  dialog = view.tag.div(id: "opener-wrap") do
    UI::DialogComponent.new(title: "Confirm", id: "focus-dialog").render_in(view) do |c|
      c.with_trigger { "Open" }
      view.tag.p("Body")
    end
  end
  before + dialog
end

# `close()` restored focus with `previouslyFocused?.focus()` — a DETACHED node's
# focus() is a silent no-op, so focus fell to <body> (a 2.4.3 loss). And
# `disconnect()` closed the dialog with no restore at all. Both paths now fall
# back to the page's stable focus anchor, `main[tabindex="-1"]` (the skip-link
# target every host layout carries).
class DialogFocusRestoreSystemTest < BrowserTestCase
  def setup
    super
    visit_scenario("dialog/focus_restore")
    page.execute_script(%(document.querySelector("main").setAttribute("tabindex", "-1")))
    # Focus a real element, then open via a SCRIPT click (which moves no focus)
    # so previouslyFocused is deterministically #before-btn.
    page.execute_script(%(document.getElementById("before-btn").focus()))
    page.execute_script(%(document.querySelector("[data-action='click->modal#open']").click()))
    find("dialog[open]")
  end

  def focused = page.evaluate_script("document.activeElement.id || document.activeElement.tagName")

  def test_close_restores_focus_to_the_opener_when_it_is_still_attached
    page.driver.browser.keyboard.type(:escape)

    assert_no_selector "dialog[open]"
    assert_equal "before-btn", focused
  end

  def test_close_falls_back_to_main_when_the_previously_focused_element_left_the_dom
    page.execute_script(%(document.getElementById("before-btn").remove()))
    page.driver.browser.keyboard.type(:escape)

    assert_no_selector "dialog[open]"
    # The restore rides the close animation's callback — wait on :focus.
    assert_selector "main:focus"
  end

  def test_disconnect_falls_back_to_main_instead_of_dropping_focus
    page.execute_script(%(document.getElementById("before-btn").remove()))
    page.execute_script(%(document.getElementById("opener-wrap").remove()))

    assert_no_selector "dialog[open]", visible: :all
    # activeElement, not :focus — this path is script-driven end to end, so the
    # page never receives real input and document.hasFocus() (which :focus
    # requires) stays false under CDP.
    assert_equal "MAIN", focused
  end
end
