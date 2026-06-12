# frozen_string_literal: true

require "render_test_helper"
load_component "number_input", "number_input_component.rb.tt"

class NumberInputRenderTest < ViewComponent::TestCase
  def test_renders_a_number_input
    render_inline(UI::NumberInputComponent.new(name: "qty"))

    assert_selector "input[type='number']"
  end

  # min / max / step / value pass straight through to the native attributes.
  def test_native_numeric_attrs_pass_through
    render_inline(UI::NumberInputComponent.new(name: "qty", min: 0, max: 100, step: 5, value: 10))

    assert_selector "input[type='number'][min='0'][max='100'][step='5'][value='10']"
  end

  # AAA semantic tokens (the design-token guarantee), not raw colors:
  def test_renders_with_aaa_tokens
    render_inline(UI::NumberInputComponent.new(name: "qty"))

    assert_selector "input.border-border-strong"
    assert_selector "input.focus-ring"
  end

  # 44px AAA touch target: the input carries the --form-input-height min-height token.
  def test_input_meets_44px_touch_target
    render_inline(UI::NumberInputComponent.new(name: "qty"))

    assert_selector "input.min-h-\\[var\\(--form-input-height\\)\\]"
  end

  # id-fallback: an id is always emitted so an external <label for=...> can target it.
  def test_emits_a_fallback_id_even_without_id_or_name
    render_inline(UI::NumberInputComponent.new)

    input_id = page.find("input[type='number']")[:id]

    refute_nil input_id, "input must carry a fallback id even without id/name"
    refute_empty input_id.to_s
  end

  def test_uses_name_as_id_fallback
    render_inline(UI::NumberInputComponent.new(name: "order[qty]"))

    assert_selector "input[type='number'][id='order_qty_']"
  end

  def test_explicit_id_wins
    render_inline(UI::NumberInputComponent.new(id: "my_qty", name: "qty"))

    assert_selector "input[type='number'][id='my_qty']"
  end

  # invalid: drives the server-validation-driven aria-invalid posture.
  def test_invalid_sets_aria_invalid
    render_inline(UI::NumberInputComponent.new(name: "qty", invalid: true))

    assert_selector "input[type='number'][aria-invalid='true']"
  end

  def test_not_invalid_by_default
    render_inline(UI::NumberInputComponent.new(name: "qty"))

    assert_no_selector "input[aria-invalid='true']"
  end

  def test_describedby_sets_aria_describedby
    render_inline(UI::NumberInputComponent.new(name: "qty", describedby: "qty_error"))

    assert_selector "input[type='number'][aria-describedby='qty_error']"
  end

  def test_no_describedby_by_default
    render_inline(UI::NumberInputComponent.new(name: "qty"))

    assert_no_selector "input[aria-describedby]"
  end

  # required: sets the native HTML required AND aria-required.
  def test_required_sets_required_and_aria_required
    render_inline(UI::NumberInputComponent.new(name: "qty", required: true))

    assert_selector "input[type='number'][required][aria-required='true']"
  end

  def test_not_required_by_default
    render_inline(UI::NumberInputComponent.new(name: "qty"))

    assert_no_selector "input[required]"
    assert_no_selector "input[aria-required]"
  end
end
