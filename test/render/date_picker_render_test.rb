# frozen_string_literal: true

require "render_test_helper"
load_component "calendar", "calendar_component.rb.tt"
load_component "date_picker", "date_picker_component.rb.tt"

# STRUCTURE-only render specs. The `date-picker` controller's BEHAVIOR (open/close,
# Escape/outside-click dismissal + focus restoration, label update) is proven by the
# app 0b browser spec — the render harness cannot exercise JS, so here we assert the
# static scaffolding the controller drives + the disclosure/label/focus a11y contract.
class DatePickerRenderTest < ViewComponent::TestCase
  def render_picker(**opts)
    render_inline(UI::DatePickerComponent.new(id: "dp", **opts))
  end

  def test_wrapper_wires_the_date_picker_controller
    render_picker

    assert_selector "div[data-controller='date-picker']", visible: :all
  end

  # The caption binds to the TEXT INPUT, not the trigger. A <label for> may only
  # name a labelable element; pointing it at a <button> named nothing and left the
  # typeable control — the one a person actually uses — unlabelled.
  def test_caption_is_a_label_bound_to_the_text_input
    render_picker

    assert_selector "label[for='dp-input']", text: "Choose date", visible: :all
    assert_selector "input#dp-input[type=text]", visible: :all
  end

  def test_custom_label_names_caption_input_and_dialog
    render_picker(label: "Due date")

    assert_selector "label[for='dp-input']", text: "Due date", visible: :all
    assert_selector "div#dp-popover[role='dialog'][aria-label='Due date']", visible: :all
  end

  # --- the typed path (#199) ------------------------------------------------

  # A known date should be typeable. Walking a calendar grid to reach a date you
  # already know is slower for everyone and a real barrier with a screen reader
  # or a switch.
  def test_text_input_is_the_typed_path_and_carries_the_format
    render_picker(format: :iso)

    assert_selector "input#dp-input[type=text][data-date-picker-target='input']" \
                    "[inputmode='numeric'][autocomplete='off']" \
                    "[data-date-picker-format='iso']", visible: :all
  end

  # Parse on blur and on Enter — never per keystroke, which would rewrite the box
  # under someone mid-type.
  def test_text_input_parses_on_commit_not_per_keystroke
    render_picker
    input = page.find("input#dp-input", visible: :all)

    assert_includes input["data-action"], "change->date-picker#commit"
    assert_includes input["data-action"], "keydown->date-picker#commitOnEnter"
    refute_includes input["data-action"], "input->"
  end

  def test_text_input_shows_the_formatted_value
    render_picker(value: Date.new(2026, 9, 3), format: :iso)

    assert_selector "input#dp-input[value='2026-09-03']", visible: :all
  end

  # min/max have to reach the typed path too, or a bound the calendar enforces is
  # trivially bypassed by typing.
  def test_bounds_reach_the_typed_path
    render_picker(min: Date.new(2026, 1, 1), max: Date.new(2026, 12, 31))

    assert_selector "input#dp-input[data-date-picker-min='2026-01-01']" \
                    "[data-date-picker-max='2026-12-31']", visible: :all
  end

  # The box says what it could not parse, in a region that announces.
  def test_error_region_is_present_and_empty_from_first_render
    render_picker
    error = page.find("#dp-error", visible: :all)

    assert_equal "status", error["role"]
    assert_equal "polite", error["aria-live"]
    assert_empty error.text.strip
  end

  def test_input_is_described_by_both_the_hint_and_the_error_region
    render_picker
    described = page.find("input#dp-input", visible: :all)["aria-describedby"].split

    assert_includes described, "dp-hint"
    assert_includes described, "dp-error"
  end

  # The calendar becomes the SECONDARY affordance, so its trigger needs a name of
  # its own — the caption now names the input.
  def test_trigger_is_an_icon_button_with_its_own_name
    render_picker(label: "Due date")
    trigger = page.find("button#dp-trigger", visible: :all)

    refute_equal "Due date", trigger["aria-label"]
    refute_empty trigger["aria-label"].to_s
  end

  # The trigger is the disclosure control: real button, popup aria, synced expanded,
  # controls the popover id, named (i18n), described by the format hint, focus-ring.
  def test_trigger_is_a_disclosure_button_with_full_aria_and_focus_ring
    render_picker

    assert_selector "button.focus-ring[type='button'][id='dp-trigger']" \
                    "[aria-haspopup='dialog'][aria-expanded='false'][aria-controls='dp-popover']" \
                    "[data-date-picker-target='trigger']" \
                    "[data-action~='click->date-picker#toggle']" \
                    "[data-action~='keydown->date-picker#triggerKeydown']", visible: :all
  end

  # A format hint with the expected pattern (default :long), wired via aria-describedby.
  def test_format_hint_is_present_and_described
    render_picker

    assert_selector "span#dp-hint", text: "Date format: MMMM D, YYYY", visible: :all
  end

  def test_format_hint_reflects_the_format_enum
    render_picker(format: :iso)

    assert_selector "span#dp-hint", text: "Date format: YYYY-MM-DD", visible: :all
  end

  # The value shows in the box a person types into, formatted by `format:` — it
  # used to sit in a <span> inside the trigger, where it could not be edited.
  def test_initial_value_uses_the_format_strftime
    render_picker(value: Date.new(2026, 3, 9), format: :short)

    assert_selector "input#dp-input[value='3/9/2026']", visible: :all
  end

  def test_placeholder_shows_when_no_value
    render_picker

    assert_selector "input#dp-input[placeholder='Pick a date']", visible: :all
  end

  # The popover is a labelled dialog, hidden until open, with Escape→focus-return wired.
  def test_popover_is_a_labelled_dialog_with_dismissal_wired
    render_picker

    assert_selector "div#dp-popover[role='dialog'][aria-label='Choose date'][tabindex='-1']" \
                    "[data-date-picker-target='popover']" \
                    "[data-action~='calendar:change->date-picker#dateSelected']" \
                    "[data-action~='keydown.esc->date-picker#closeAndFocus']", visible: :all
  end

  # The popover is non-modal (focus is not trapped): the false aria-modal must be gone.
  def test_popover_is_not_falsely_aria_modal
    render_picker

    assert_no_selector "[role='dialog'][aria-modal]", visible: :all
  end

  def test_decorative_icon_is_aria_hidden
    render_picker

    assert_selector "button#dp-trigger svg[aria-hidden='true']", visible: :all
  end

  def test_hidden_input_posts_iso_value_when_named
    render_picker(name: "event[date]", value: Date.new(2026, 3, 9))

    assert_selector "input[type='hidden'][name='event[date]'][value='2026-03-09']" \
                    "[data-date-picker-target='hidden']", visible: :all
  end

  def test_no_hidden_input_without_a_name
    render_picker

    assert_no_selector "input[type='hidden']", visible: :all
  end

  def test_unknown_format_raises
    error = assert_raises(ArgumentError) do
      UI::DatePickerComponent.new(format: :bogus)
    end
    assert_match(/unknown format/, error.message)
  end

  # Regression guard: the box-shadow ring anti-pattern must never come back.
  def test_no_box_shadow_ring_or_outline_none
    render_picker
    html = page.native.to_html

    refute_includes html, "focus-visible:ring-"
    refute_includes html, "outline-none"
  end

  # html_attrs pass through onto the root, and a caller data-* must NOT clobber the
  # component's own data-controller (attr-clobber watch).
  def test_passes_through_html_attrs_and_preserves_data_controller
    render_inline(UI::DatePickerComponent.new(id: "dp", data: {testid: "picker"}))

    assert_selector "div[data-controller='date-picker'][data-testid='picker']", visible: :all
  end

  # A caller-supplied class merges onto the root without dropping the wrapper layout.
  def test_merges_caller_class_onto_the_root
    render_inline(UI::DatePickerComponent.new(id: "dp", class: "mt-4"))

    assert_selector "div.mt-4.relative.inline-block", visible: :all
  end
end
