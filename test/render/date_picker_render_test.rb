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

  # The visible caption is a real <label for> bound to the trigger button.
  def test_caption_is_a_label_bound_to_the_trigger
    render_picker

    assert_selector "label[for='dp-trigger']", text: "Choose date", visible: :all
  end

  def test_custom_label_names_caption_trigger_and_dialog
    render_picker(label: "Due date")

    assert_selector "label[for='dp-trigger']", text: "Due date", visible: :all
    assert_selector "button#dp-trigger[aria-label='Due date']", visible: :all
    assert_selector "div#dp-popover[role='dialog'][aria-label='Due date']", visible: :all
  end

  # The trigger is the disclosure control: real button, popup aria, synced expanded,
  # controls the popover id, named (i18n), described by the format hint, focus-ring.
  def test_trigger_is_a_disclosure_button_with_full_aria_and_focus_ring
    render_picker

    assert_selector "button.focus-ring[type='button'][id='dp-trigger']" \
                    "[aria-haspopup='dialog'][aria-expanded='false'][aria-controls='dp-popover']" \
                    "[aria-label='Choose date'][aria-describedby='dp-hint']" \
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

  # The initial trigger label uses the chosen strftime when a value is given.
  def test_initial_label_uses_the_format_strftime
    render_picker(value: Date.new(2026, 3, 9), format: :short)

    assert_selector "button#dp-trigger span[data-date-picker-target='label']", text: "3/9/2026", visible: :all
  end

  def test_placeholder_shows_when_no_value
    render_picker

    assert_selector "span[data-date-picker-target='label']", text: "Pick a date", visible: :all
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
