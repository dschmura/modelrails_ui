# frozen_string_literal: true

require "render_test_helper"
load_component "range", "range_component.rb.tt"

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
end
