# frozen_string_literal: true

require "system_test_helper"
load_component "calendar", "calendar_component.rb.tt"
load_component "date_picker", "date_picker_component.rb.tt"

# The typed path is BEHAVIOUR: parsing, bounds and the error state only exist once
# the controller runs, so the render lane is blind to all of it. This is the lane
# that can fail when typing a date does not work.
BrowserHarness.scenario("date_picker/basic", controllers: %w[date-picker calendar],
  modules: %w[overlays/top_layer keyboard/keyboard_nav]) do
  view = ActionController::Base.new.view_context
  UI::DatePickerComponent.new(id: "dp", name: "due_on", label: "Due date", format: :iso).render_in(view)
end

BrowserHarness.scenario("date_picker/bounded", controllers: %w[date-picker calendar],
  modules: %w[overlays/top_layer keyboard/keyboard_nav]) do
  view = ActionController::Base.new.view_context
  UI::DatePickerComponent.new(id: "dp", name: "due_on", label: "Due date", format: :iso,
    min: Date.new(2026, 1, 1), max: Date.new(2026, 12, 31)).render_in(view)
end

# Two on one form: the case the issue names, where both dialogs used to carry the
# same accessible name.
BrowserHarness.scenario("date_picker/pair", controllers: %w[date-picker calendar],
  modules: %w[overlays/top_layer keyboard/keyboard_nav]) do
  view = ActionController::Base.new.view_context
  UI::DatePickerComponent.new(id: "from", name: "from", label: "From", format: :iso).render_in(view) +
    UI::DatePickerComponent.new(id: "to", name: "to", label: "To", format: :iso).render_in(view)
end

class DatePickerSystemTest < BrowserTestCase
  def input = find("#dp-input")
  def hidden = page.evaluate_script(%{document.querySelector("[data-date-picker-target=hidden]").value})
  # The attribute value itself, not a predicate: the assertion then names what
  # the DOM actually says when it fails.
  def aria_invalid = page.evaluate_script(%{document.querySelector("#dp-input").getAttribute("aria-invalid")})
  def error_text = find("#dp-error", visible: :all).text.strip

  # The whole point of the issue: a date you already know should not require
  # walking a grid to reach.
  def test_typing_a_date_sets_the_value_without_opening_the_calendar
    visit_scenario("date_picker/basic")
    input.set("2026-09-03")
    input.send_keys(:enter)

    assert_equal "2026-09-03", hidden
    assert_no_selector "[data-date-picker-target=popover][data-open=true]"
    assert_no_stimulus_errors
  end

  def test_blurring_commits_too
    visit_scenario("date_picker/basic")
    input.set("2026-09-03")
    page.execute_script(%{document.querySelector("#dp-input").blur()})

    assert_equal "2026-09-03", hidden
  end

  # Normalised back into the box, so the field always shows what was stored.
  def test_a_committed_value_is_written_back_formatted
    visit_scenario("date_picker/basic")
    input.set("2026-9-3")
    input.send_keys(:enter)

    assert_equal "2026-09-03", hidden
    assert_equal "2026-09-03", input.value
  end

  def test_clearing_the_box_clears_the_value
    visit_scenario("date_picker/basic")
    input.set("2026-09-03")
    input.send_keys(:enter)
    input.set("")
    input.send_keys(:enter)

    assert_equal "", hidden
    assert_equal "false", aria_invalid
  end

  # Unparseable text must not silently revert or silently apply: the text stays
  # for correction, the stored value is untouched, and the box says why.
  def test_unparseable_text_is_reported_and_changes_nothing
    visit_scenario("date_picker/basic")
    input.set("2026-09-03")
    input.send_keys(:enter)
    input.set("not a date")
    input.send_keys(:enter)

    assert_equal "true", aria_invalid
    assert_equal "2026-09-03", hidden, "a rejected entry must not change the stored value"
    assert_equal "not a date", input.value, "the text must stay for correction"
    refute_empty error_text
  end

  def test_correcting_a_rejected_entry_clears_the_error
    visit_scenario("date_picker/basic")
    input.set("not a date")
    input.send_keys(:enter)

    assert_equal "true", aria_invalid

    input.set("2026-09-03")
    input.send_keys(:enter)

    assert_equal "false", aria_invalid
    assert_empty error_text
    assert_equal "2026-09-03", hidden
  end

  # A bound the calendar enforces is worthless if typing walks straight past it.
  def test_a_typed_date_outside_the_bounds_is_refused
    visit_scenario("date_picker/bounded")
    input.set("2025-06-01")
    input.send_keys(:enter)

    assert_equal "true", aria_invalid
    assert_equal "", hidden
    refute_empty error_text
  end

  def test_a_typed_date_inside_the_bounds_is_accepted
    visit_scenario("date_picker/bounded")
    input.set("2026-06-01")
    input.send_keys(:enter)

    assert_equal "false", aria_invalid
    assert_equal "2026-06-01", hidden
  end

  # The calendar stays available — this is an addition, not a replacement.
  def test_the_calendar_still_sets_the_value_and_syncs_the_box
    visit_scenario("date_picker/basic")
    find("#dp-trigger").click

    assert_selector "[data-date-picker-target=popover][data-open=true]"
    first("[role=gridcell] button:not([disabled])", minimum: 1).click

    refute_empty hidden
    assert_equal hidden, input.value
    assert_no_stimulus_errors
  end

  # Two pickers on one form were indistinguishable by name: both dialogs carried
  # the same aria-label, and the trigger took the caption's text.
  def test_two_pickers_on_one_form_have_distinct_names
    visit_scenario("date_picker/pair")
    dialog_names = page.all("[role=dialog]", visible: :all).map { |d| d["aria-label"] }
    trigger_names = page.all("button[aria-haspopup=dialog]", visible: :all).map { |b| b["aria-label"] }

    assert_equal dialog_names.uniq.length, dialog_names.length, "duplicate dialog names: #{dialog_names.inspect}"
    assert_equal trigger_names.uniq.length, trigger_names.length, "duplicate trigger names: #{trigger_names.inspect}"
  end

  def test_a_pair_of_pickers_passes_a_structural_axe_audit
    visit_scenario("date_picker/pair")

    assert_axe_clean
  end

  def test_the_open_calendar_still_passes_a_structural_axe_audit
    visit_scenario("date_picker/basic")
    find("#dp-trigger").click

    assert_axe_clean
  end
end
