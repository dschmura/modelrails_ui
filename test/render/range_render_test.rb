# frozen_string_literal: true

require "render_test_helper"
load_component "range", "range_component.rb.tt"

# STRUCTURE only. The live readout sync (drag the slider → <output> text updates)
# is verified by the app's 0b browser spec, not here — the render harness has no
# JS runtime, so we assert the wiring (data-controller / data-action / targets)
# the `range` Stimulus controller hooks into, not the runtime behavior.
class RangeRenderTest < ViewComponent::TestCase
  def test_renders_native_range_input_with_min_max_step
    render_inline(UI::RangeComponent.new(min: 0, max: 10, step: 2))

    assert_selector "input[type='range'][min='0'][max='10'][step='2']"
  end

  def test_value_is_emitted_when_supplied
    render_inline(UI::RangeComponent.new(value: 7))

    assert_selector "input[type='range'][value='7']"
  end

  def test_value_is_omitted_when_nil
    render_inline(UI::RangeComponent.new)

    assert_no_selector "input[type='range'][value]"
  end

  # AAA semantic token (the design-token guarantee), not raw Tailwind:
  def test_renders_with_aaa_token
    render_inline(UI::RangeComponent.new)

    assert_selector "input.accent-interactive"
  end

  def test_invalid_sets_aria_invalid
    render_inline(UI::RangeComponent.new(invalid: true))

    assert_selector "input[type='range'][aria-invalid='true']"
  end

  def test_not_invalid_omits_aria_invalid
    render_inline(UI::RangeComponent.new)

    assert_no_selector "input[type='range'][aria-invalid]"
  end

  def test_describedby_sets_aria_describedby
    render_inline(UI::RangeComponent.new(describedby: "volume-help"))

    assert_selector "input[type='range'][aria-describedby='volume-help']"
  end

  def test_no_describedby_omits_aria_describedby
    render_inline(UI::RangeComponent.new)

    assert_no_selector "input[type='range'][aria-describedby]"
  end

  def test_id_from_explicit_id_attr
    render_inline(UI::RangeComponent.new(id: "my_range"))

    assert_selector "input#my_range"
  end

  def test_id_falls_back_to_name
    render_inline(UI::RangeComponent.new(name: "post[volume]"))

    assert_selector "input#post_volume_"
  end

  def test_id_is_always_emitted_with_neither_id_nor_name
    render_inline(UI::RangeComponent.new)

    assert_selector "input[type='range'][id]"
  end

  # --- show_value: opt-in <output> readout (STRUCTURE) ---

  def test_show_value_wraps_input_in_range_controller
    render_inline(UI::RangeComponent.new(show_value: true))

    assert_selector "div[data-controller='range'] input[type='range']"
  end

  def test_show_value_wires_input_target_and_sync_action
    render_inline(UI::RangeComponent.new(show_value: true))

    assert_selector "input[data-range-target='input'][data-action~='input->range#sync']"
  end

  def test_show_value_renders_output_targeting_input_id_with_aaa_token
    render_inline(UI::RangeComponent.new(id: "vol", value: 60, show_value: true))

    assert_selector "output[for='vol'][data-range-target='output'].text-text-body", text: "60"
  end

  def test_show_value_output_uses_native_midpoint_when_value_nil
    render_inline(UI::RangeComponent.new(min: 0, max: 100, show_value: true))

    assert_selector "output[data-range-target='output']", text: "50"
  end

  # Default (show_value omitted) is byte-unchanged: no wrapper, no output.
  def test_default_omits_output_and_range_controller
    render_inline(UI::RangeComponent.new)

    assert_no_selector "output"
    assert_no_selector "[data-controller='range']"
  end
end
