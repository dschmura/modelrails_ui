# frozen_string_literal: true

require "render_test_helper"
load_component "textarea", "textarea_component.rb.tt"

class TextareaRenderTest < ViewComponent::TestCase
  def test_renders_a_textarea
    render_inline(UI::TextareaComponent.new)

    assert_selector "textarea"
  end

  def test_value_renders_as_the_textarea_body
    render_inline(UI::TextareaComponent.new(value: "Hello world"))

    assert_selector "textarea", text: "Hello world"
  end

  # AAA semantic tokens (the design-token guarantee), not raw Tailwind.
  # BASE styling on every field (chained classes = one assertion).
  def test_renders_base_aaa_tokens
    render_inline(UI::TextareaComponent.new)

    assert_selector "textarea.block.w-full.rounded-md.border.focus\\:ring-2"
  end

  # NORMAL styling on a non-invalid field.
  def test_renders_normal_aaa_tokens_when_valid
    render_inline(UI::TextareaComponent.new)

    assert_selector "textarea.border-border-strong.bg-surface-raised.text-text-heading.focus\\:ring-interactive-focus"
  end

  # invalid: drives aria-invalid AND swaps NORMAL styling for the ERROR token.
  def test_invalid_sets_aria_invalid
    render_inline(UI::TextareaComponent.new(invalid: true))

    assert_selector "textarea[aria-invalid='true']"
  end

  def test_invalid_applies_error_styling
    render_inline(UI::TextareaComponent.new(invalid: true))

    assert_selector "textarea.border-danger.bg-danger-surface.text-danger"
  end

  def test_not_invalid_by_default_uses_normal_styling
    render_inline(UI::TextareaComponent.new)

    assert_no_selector "textarea[aria-invalid='true']"
    assert_no_selector "textarea.border-danger"
    assert_selector "textarea.border-border-strong"
  end

  def test_required_sets_required_and_aria_required
    render_inline(UI::TextareaComponent.new(required: true))

    assert_selector "textarea[required]"
    assert_selector "textarea[aria-required='true']"
  end

  def test_not_required_by_default
    render_inline(UI::TextareaComponent.new)

    assert_no_selector "textarea[required]"
    assert_no_selector "textarea[aria-required='true']"
  end

  def test_describedby_sets_aria_describedby
    render_inline(UI::TextareaComponent.new(describedby: "bio_error"))

    assert_selector "textarea[aria-describedby='bio_error']"
  end

  def test_no_describedby_by_default
    render_inline(UI::TextareaComponent.new)

    assert_no_selector "textarea[aria-describedby]"
  end
end
