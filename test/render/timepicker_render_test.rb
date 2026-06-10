# frozen_string_literal: true

require "render_test_helper"
require "securerandom"
load_component "timepicker", "timepicker_component.rb.tt"

# STRUCTURE-only render specs. The `timepicker` controller's BEHAVIOR (open/close,
# stepping, aria-value* sync, AM/PM toggle) is proven by the app 0b browser spec —
# the render harness cannot exercise JS, so here we assert the static scaffolding the
# controller relies on plus the disclosure/spinbutton ARIA contract.
class TimepickerRenderTest < ViewComponent::TestCase
  def render_timepicker(**opts)
    render_inline(UI::TimepickerComponent.new(**opts))
  end

  # --- Disclosure (trigger → popover) ---

  def test_wrapper_wires_the_timepicker_controller_with_format_and_step
    render_timepicker(format: :h12, step: 15)

    assert_selector "div[data-controller='timepicker']" \
                    "[data-timepicker-format-value='h12']" \
                    "[data-timepicker-step-value='15']", visible: :all
  end

  def test_trigger_is_a_real_button_with_full_disclosure_aria
    render_timepicker(id: "tp1")

    assert_selector "button[type='button'][aria-haspopup='dialog'][aria-expanded='false']" \
                    "[aria-controls='tp1-popover'][aria-describedby='tp1-hint']" \
                    "[data-timepicker-target='trigger']" \
                    "[data-action~='click->timepicker#toggle']", visible: :all
  end

  def test_popover_is_a_labelled_dialog_addressed_by_the_trigger
    render_timepicker(id: "tp2", label: "Start time")

    assert_selector "div#tp2-popover[role='dialog'][aria-label='Start time']" \
                    "[aria-modal='true'][tabindex='-1']" \
                    "[data-timepicker-target='popover']", visible: :all
  end

  # --- Spinbutton ARIA contract ---

  def test_hour_and_minute_are_spinbuttons_with_value_range
    render_timepicker(value: "09:30")

    assert_selector "input[role='spinbutton'][data-timepicker-target='hour']" \
                    "[aria-valuemin='0'][aria-valuemax='23']" \
                    "[aria-valuenow='9'][aria-valuetext='09']", visible: :all
    assert_selector "input[role='spinbutton'][data-timepicker-target='minute']" \
                    "[aria-valuemin='0'][aria-valuemax='59']" \
                    "[aria-valuenow='30'][aria-valuetext='30']", visible: :all
  end

  def test_h12_format_caps_the_hour_spinbutton_at_12_and_adds_ampm
    render_timepicker(format: :h12, value: "11:00")

    assert_selector "input[role='spinbutton'][data-timepicker-target='hour'][aria-valuemax='12']", visible: :all
    assert_selector "[role='spinbutton'][data-timepicker-target='ampm'][aria-valuetext='AM']" \
                    "[tabindex='0']", visible: :all
  end

  def test_h24_format_has_no_ampm_spinbutton
    render_timepicker(format: :h24)

    assert_no_selector "[data-timepicker-target='ampm']", visible: :all
  end

  # --- Accessible names (i18n) ---

  def test_spinbuttons_have_i18n_accessible_names
    render_timepicker(format: :h12)

    assert_selector "input[data-timepicker-target='hour'][aria-label='Hour']", visible: :all
    assert_selector "input[data-timepicker-target='minute'][aria-label='Minute']", visible: :all
    assert_selector "[data-timepicker-target='ampm'][aria-label='AM or PM']", visible: :all
  end

  def test_trigger_and_popover_share_the_i18n_default_accessible_name
    render_timepicker

    assert_selector "button[aria-label='Pick time']", visible: :all
    assert_selector "div[role='dialog'][aria-label='Pick time']", visible: :all
  end

  def test_custom_label_names_trigger_popover_and_visible_text
    render_timepicker(label: "Meeting time")

    assert_selector "button[aria-label='Meeting time']", text: "Meeting time", visible: :all
    assert_selector "div[role='dialog'][aria-label='Meeting time']", visible: :all
  end

  def test_value_takes_precedence_over_label_in_the_visible_trigger_text
    render_timepicker(value: "14:45")

    assert_selector "span[data-timepicker-target='label']", text: "14:45", visible: :all
  end

  # --- Format hint wired to the trigger ---

  def test_hint_describes_the_format_and_is_referenced_by_the_trigger
    render_timepicker(id: "tp3", format: :h24)

    assert_selector "span#tp3-hint", text: "HH:MM (24-hour)", visible: :all
  end

  def test_h12_hint_announces_the_12_hour_format
    render_timepicker(format: :h12)

    assert_text "HH:MM AM/PM (12-hour)"
  end

  # --- Focus-ring (the AAA offset outline, on every focusable control) ---

  def test_trigger_carries_the_focus_ring
    render_timepicker

    assert_selector "button.focus-ring[data-timepicker-target='trigger']", visible: :all
  end

  def test_spinbutton_inputs_carry_the_focus_ring
    render_timepicker

    assert_selector "input.focus-ring[data-timepicker-target='hour']", visible: :all
    assert_selector "input.focus-ring[data-timepicker-target='minute']", visible: :all
  end

  def test_stepper_buttons_carry_the_focus_ring_but_are_decorative
    render_timepicker

    # ▲/▼ steppers: focus-ring present, but aria-hidden + tabindex=-1 (the spinbutton
    # inputs are the keyboard target, not these).
    assert_selector "button.focus-ring[aria-hidden='true'][tabindex='-1']", count: 4, visible: :all
  end

  # The aria-state utility classes (which embed `[`/`:`) survive the merge — assert via
  # substring since `.` selectors can't match a class literal containing brackets.
  def test_trigger_keeps_the_aria_expanded_border_utility
    render_timepicker

    assert_selector "button[class*='aria-expanded:border-border-focus']", visible: :all
  end

  def test_popover_keeps_the_data_open_block_utility
    render_timepicker

    assert_selector "div[class*='data-[open=true]:block']", visible: :all
  end

  # --- AAA semantic tokens, not raw palette ---

  def test_renders_with_aaa_tokens
    render_timepicker

    assert_selector "div[role='dialog'].bg-surface-overlay", visible: :all
    assert_selector "input.border-border-strong", visible: :all
  end

  # --- Fail-loud ---

  def test_unknown_format_raises
    error = assert_raises(ArgumentError) do
      UI::TimepickerComponent.new(format: :military)
    end
    assert_match(/unknown format/, error.message)
  end

  def test_step_is_clamped_into_range
    # step is a clamped free integer (1..60), not an enum — out-of-range coerces, not raises.
    render_inline(UI::TimepickerComponent.new(step: 999))

    assert_selector "div[data-timepicker-step-value='60']", visible: :all
  end

  # --- Regression guard: the box-shadow ring anti-pattern must never come back ---

  def test_no_box_shadow_ring_or_outline_none
    render_timepicker(format: :h12)
    html = page.native.to_html

    refute_includes html, "focus-visible:ring-"
    refute_includes html, "focus:ring-"
    refute_includes html, "outline-none"
  end

  # --- html_attrs passthrough (incl. data-controller preserved past caller data) ---

  def test_passes_through_html_attrs_onto_the_root
    render_inline(UI::TimepickerComponent.new(id: "my-tp", data: {testid: "tp"}))

    # A caller-supplied id is consumed to derive the popover/trigger/hint ids (like the
    # date_picker sibling); the root still wires the controller, and the caller's data
    # merges WITHOUT clobbering data-controller (the attr-clobber watch).
    assert_selector "div[data-controller='timepicker'][data-testid='tp']", visible: :all
    assert_selector "div#my-tp-popover[role='dialog']", visible: :all
    assert_selector "button#my-tp-trigger[aria-controls='my-tp-popover']", visible: :all
  end

  def test_caller_class_merges_onto_the_root_without_clobbering_wrapper
    render_inline(UI::TimepickerComponent.new(class: "mt-4"))

    assert_selector "div.mt-4.relative.inline-block[data-controller='timepicker']", visible: :all
  end
end
