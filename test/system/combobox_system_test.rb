# frozen_string_literal: true

require "system_test_helper"
require "securerandom"
load_component "combobox", "combobox_component.rb.tt"

OPTIONS = [
  {value: "us", label: "United States"},
  {value: "ca", label: "Canada"},
  {value: "mx", label: "Mexico"}
].freeze

BrowserHarness.scenario("combobox/basic", controllers: %w[combobox], modules: %w[overlays/top_layer keyboard/keyboard_nav]) do
  view = ActionController::Base.new.view_context
  UI::ComboboxComponent.new(name: "country", label: "Country", options: OPTIONS).render_in(view)
end

BrowserHarness.scenario("combobox/two", controllers: %w[combobox], modules: %w[overlays/top_layer keyboard/keyboard_nav]) do
  view = ActionController::Base.new.view_context
  UI::ComboboxComponent.new(name: "origin", label: "Origin", options: OPTIONS).render_in(view) +
    UI::ComboboxComponent.new(name: "destination", label: "Destination", options: OPTIONS).render_in(view)
end

# Filtering, activedescendant and commit are all runtime behaviour. The duplicate-id case
# especially: ids minted by the controller at runtime cannot be checked from markup at all.
class ComboboxSystemTest < BrowserTestCase
  def input = find("[data-combobox-target=input]")

  def test_focusing_the_input_opens_the_listbox
    visit_scenario("combobox/basic")
    input.click

    assert_selector "[role=listbox]"
    assert_selector "[role=option]", count: 3
  end

  def test_typing_filters_the_options
    visit_scenario("combobox/basic")
    input.click
    input.send_keys("can")

    assert_selector "[role=option]", count: 1, text: "Canada"
  end

  def test_no_match_shows_the_empty_state
    visit_scenario("combobox/basic")
    input.click
    input.send_keys("zzzz")

    assert_no_selector "[role=option]"
    assert_selector "[data-combobox-target=empty]"
  end

  # A listbox with every option hidden is a container advertising children it does
  # not have. It goes away entirely, leaving the status message as what a reader
  # reaches — so the disappearance is asserted first, before what must remain (#218).
  def test_no_match_hides_the_listbox_itself
    visit_scenario("combobox/basic")
    input.click
    input.send_keys("zzzz")

    assert_no_selector "[role=listbox]"
    assert_selector "[data-combobox-target=empty]", text: "No results found."
  end

  # The zero-match state is its own tree, and the existing audit never sees it:
  # it runs with all options visible and the status message hidden.
  def test_the_zero_match_state_passes_a_structural_axe_audit
    visit_scenario("combobox/basic")
    input.click
    input.send_keys("zzzz")

    assert_selector "[data-combobox-target=empty]"
    assert_axe_clean
  end

  # Zero-match filter → Escape → ArrowUp must reopen, entering at the LAST
  # option. close() leaves the zero-match hidden states in place, so with the
  # reopen branch behind the empty-visible guard no key could ever reopen the
  # listbox (aria-expanded stuck false; only a printable keystroke recovered).
  def test_arrow_up_reopens_after_escape_from_a_zero_match_filter
    visit_scenario("combobox/basic")
    input.click
    input.send_keys("zzzz")
    press(:Escape)
    press(:Up)

    assert_selector "[role=option]", count: 3
    assert_equal "Mexico", find("##{input["aria-activedescendant"]}").text
  end

  def test_arrow_down_reopens_after_escape_from_a_zero_match_filter_at_the_first_option
    visit_scenario("combobox/basic")
    input.click
    input.send_keys("zzzz")
    press(:Escape)
    press(:Down)

    assert_selector "[role=option]", count: 3
    assert_equal "United States", find("##{input["aria-activedescendant"]}").text
  end

  # aria-activedescendant must name a real element — a stale or absent id silently breaks
  # the announcement while looking fine in the DOM.
  def test_arrow_down_points_activedescendant_at_a_real_option
    visit_scenario("combobox/basic")
    input.click
    press(:Down)

    resolved = page.evaluate_script(<<~JS)
      (() => {
        const input = document.querySelector("[data-combobox-target=input]");
        const id = input.getAttribute("aria-activedescendant");
        const el = id && document.getElementById(id);
        return JSON.stringify({ id: id, exists: !!el, isOption: el ? el.getAttribute("role") === "option" : false });
      })()
    JS
    state = JSON.parse(resolved)

    assert state["exists"], "aria-activedescendant=#{state["id"].inspect} names no element"
    assert state["isOption"], "aria-activedescendant does not name an option"
  end

  def test_choosing_an_option_commits_the_value
    visit_scenario("combobox/basic")
    input.click
    find("[role=option]", text: "Mexico").click

    assert_equal "mx", page.evaluate_script(%{document.querySelector("[data-combobox-target=hidden]").value})
    assert_no_stimulus_errors
  end

  # The runtime half of the duplicate-id fix: option ids are minted by the controller, so
  # two instances with a shared prefix collide and aria-activedescendant becomes ambiguous.
  def test_option_ids_are_unique_across_two_instances
    visit_scenario("combobox/two")
    page.all("[data-combobox-target=input]").each(&:click)
    ids = page.evaluate_script(%{[...document.querySelectorAll("[role=option]")].map(o => o.id)})

    assert_operator ids.length, :>=, 6
    assert_equal ids.uniq.length, ids.length, "duplicate option ids across instances: #{ids.inspect}"
  end

  # --- form integration (#203) ---------------------------------------------

  # Assigning `input.value` in JS fires nothing. A form that submits on `change`
  # (the reference app's filter form) therefore never hears a combobox selection
  # while every other control in the same form is heard. The listener sits on
  # `document`, so this proves the event BUBBLES as well as that it fires.
  def test_choosing_an_option_dispatches_change_from_the_hidden_input
    visit_scenario("combobox/basic")
    page.execute_script(<<~JS)
      window.__changeTargets = []
      document.addEventListener("change", (event) => {
        window.__changeTargets.push(event.target.dataset.comboboxTarget)
      })
    JS
    input.click
    find("[role=option]", text: "Mexico").click

    assert_equal ["hidden"], page.evaluate_script("window.__changeTargets")
    assert_no_stimulus_errors
  end

  # --- the text input's own id (#202) --------------------------------------

  # The point of the derived id: `fill_in` can address the input directly, so a
  # host's specs stop reaching for `find("input[role=combobox][aria-label=…]")`.
  def test_fill_in_reaches_the_text_input_by_its_id
    visit_scenario("combobox/basic")
    id = page.evaluate_script(%{document.querySelector("[data-combobox-target=input]").id})

    refute_empty id.to_s, "the text input has no id for fill_in to address"
    fill_in id, with: "can"

    assert_selector "[role=option]", count: 1, text: "Canada"
  end

  def test_open_combobox_passes_a_structural_axe_audit
    visit_scenario("combobox/basic")
    input.click

    assert_axe_clean
  end
end

# A control after the widget, so "Tab left the combobox" and "focus went somewhere
# outside" are positive assertions about where focus landed rather than assertions
# that it is merely not on an option.
BrowserHarness.scenario("combobox/in_a_form", controllers: %w[combobox],
  modules: %w[overlays/top_layer keyboard/keyboard_nav]) do
  view = ActionController::Base.new.view_context
  UI::ComboboxComponent.new(name: "country", label: "Country", options: OPTIONS).render_in(view) +
    view.tag.button("After", type: "button", id: "after")
end

# Filtering changes what is on offer, and nothing said so: narrowing 40 options to 3
# announced only the newly active option. The count has to come from a live region
# that was registered BEFORE the change — a region revealed together with its text is
# inserted-with-content, and assistive tech drops it (#166).
class ComboboxResultsAnnouncementTest < BrowserTestCase
  def input = find("[data-combobox-target=input]")
  def status = "[data-combobox-target=status]"
  def status_text = page.evaluate_script(%{document.querySelector("[data-combobox-target=status]").textContent.trim()})

  # The panel is hidden until the widget opens, so a status region inside it would be
  # out of the tree at render — exactly the bug. It lives on the wrapper.
  def test_the_status_region_is_present_and_empty_before_any_interaction
    visit_scenario("combobox/basic")

    assert_selector status, visible: :all
    assert_equal "", status_text
    assert_equal "false", page.evaluate_script(
      %{String(document.querySelector("[data-combobox-target=status]").closest("[data-combobox-target=panel]") !== null)}
    ), "the status region sits inside the panel, which is hidden at render"
  end

  def test_narrowing_the_options_announces_how_many_remain
    visit_scenario("combobox/basic")
    input.click
    input.send_keys("can")

    assert_selector "[role=option]", count: 1, text: "Canada"
    assert_equal "1 result available.", status_text
  end

  # Opening filters against an empty query, so the full set is what is on offer.
  def test_opening_announces_the_full_count
    visit_scenario("combobox/basic")
    input.click

    assert_equal "3 results available.", status_text
  end

  # "a" matches United States and Canada but not Mexico — a real 3 → 2 narrowing,
  # which is the plural path rather than the singular one above.
  def test_narrowing_to_several_announces_the_plural_count
    visit_scenario("combobox/basic")
    input.click
    input.send_keys("a")

    assert_selector "[role=option]", count: 2
    assert_equal "2 results available.", status_text
  end

  def test_zero_matches_are_announced_in_the_status_region
    visit_scenario("combobox/basic")
    input.click
    input.send_keys("zzzz")

    assert_equal "No results found.", status_text
  end

  # One announcer, not two. The visible message is a visual affordance; if it were
  # also a live region the same text would be spoken twice.
  def test_the_visible_empty_message_is_not_a_second_live_region
    visit_scenario("combobox/basic")

    assert_no_selector "[data-combobox-target=empty][role=status]", visible: :all
    assert_no_selector "[data-combobox-target=empty][aria-live]", visible: :all
  end

  def test_the_announcing_combobox_passes_a_structural_axe_audit
    visit_scenario("combobox/basic")
    input.click
    input.send_keys("can")

    assert_axe_clean
  end
end

# The APG combobox keeps DOM focus on the text input and points at the active option
# with aria-activedescendant. Three behaviours enforce that, and they are one change:
# dismissing on focus-out without the pointer guard would close the panel on the way
# to a click (#217).
class ComboboxFocusContractTest < BrowserTestCase
  def input = find("[data-combobox-target=input]")
  def active_id = page.evaluate_script("document.activeElement && document.activeElement.id")
  def active_role = page.evaluate_script("document.activeElement && document.activeElement.getAttribute('role')")
  def panel = "[data-combobox-target=panel]"

  # Options ship as <button>, which is natively focusable: without tabindex=-1 Tab
  # walks the whole list instead of leaving the widget.
  def test_tab_from_the_input_leaves_the_widget
    visit_scenario("combobox/in_a_form")
    input.click
    input.send_keys(:tab)

    refute_equal "option", active_role, "Tab moved focus onto a listbox option"
    assert_equal "after", active_id
  end

  def test_focus_leaving_the_widget_closes_the_panel
    visit_scenario("combobox/in_a_form")
    input.click

    assert_selector panel
    page.execute_script(%{document.getElementById("after").focus()})

    assert_no_selector panel
  end

  # Focus staying inside the widget must NOT close it — the guard against a
  # focus-out handler that fires on any internal focus move.
  def test_focus_moving_within_the_widget_keeps_the_panel_open
    visit_scenario("combobox/in_a_form")
    input.click

    assert_selector panel
    page.execute_script(%{document.querySelector("[role=option]").focus()})

    assert_selector panel
  end

  # Why the mousedown guard is load-bearing: without it the pointer moves focus onto
  # the option button, select() then hides the panel, and focus falls to <body> — the
  # user is returned nowhere. The selection itself is asserted first.
  def test_a_pointer_selection_leaves_focus_on_the_input
    visit_scenario("combobox/in_a_form")
    input.click
    find("[role=option]", text: "Canada").click

    assert_equal "Canada", page.evaluate_script(%{document.querySelector("[data-combobox-target=input]").value})
    assert_equal page.evaluate_script(%{document.querySelector("[data-combobox-target=input]").id}), active_id,
      "focus did not return to the combobox input after a pointer selection"
  end
end
