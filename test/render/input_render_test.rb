# frozen_string_literal: true

require "render_test_helper"
load_component "input", "input_component.rb.tt"

class InputRenderTest < ViewComponent::TestCase
  def test_renders_a_text_input_by_default
    render_inline(UI::InputComponent.new)

    assert_selector "input[type='text']"
  end

  def test_type_passes_through
    render_inline(UI::InputComponent.new(type: "email"))

    assert_selector "input[type='email']"
  end

  # AAA semantic tokens (the design-token guarantee), not raw Tailwind.
  # BASE styling on every field (chained classes = one assertion).
  def test_renders_base_aaa_tokens
    render_inline(UI::InputComponent.new)

    assert_selector "input.block.w-full.rounded-md.border.focus\\:ring-2"
  end

  # NORMAL styling on a non-invalid field.
  def test_renders_normal_aaa_tokens_when_valid
    render_inline(UI::InputComponent.new)

    assert_selector "input.border-border-strong.bg-surface-raised.text-text-heading.focus\\:ring-interactive-focus"
  end

  # invalid: drives the server-validation-driven aria-invalid posture AND
  # swaps NORMAL styling for the ERROR token.
  def test_invalid_sets_aria_invalid
    render_inline(UI::InputComponent.new(invalid: true))

    assert_selector "input[aria-invalid='true']"
  end

  def test_invalid_applies_error_styling
    render_inline(UI::InputComponent.new(invalid: true))

    assert_selector "input.border-danger.bg-danger-surface.text-danger"
  end

  def test_not_invalid_by_default_uses_normal_styling
    render_inline(UI::InputComponent.new)

    assert_no_selector "input[aria-invalid='true']"
    assert_no_selector "input.border-danger"
    assert_selector "input.border-border-strong"
  end

  def test_required_sets_required_and_aria_required
    render_inline(UI::InputComponent.new(required: true))

    assert_selector "input[required]"
    assert_selector "input[aria-required='true']"
  end

  def test_not_required_by_default
    render_inline(UI::InputComponent.new)

    assert_no_selector "input[required]"
    assert_no_selector "input[aria-required='true']"
  end

  def test_describedby_sets_aria_describedby
    render_inline(UI::InputComponent.new(describedby: "email_error"))

    assert_selector "input[aria-describedby='email_error']"
  end

  def test_no_describedby_by_default
    render_inline(UI::InputComponent.new)

    assert_no_selector "input[aria-describedby]"
  end
end
