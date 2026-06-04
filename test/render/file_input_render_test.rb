# frozen_string_literal: true

require "render_test_helper"
load_component "file_input", "file_input_component.rb.tt"

class FileInputRenderTest < ViewComponent::TestCase
  def test_renders_a_file_input
    render_inline(UI::FileInputComponent.new)

    assert_selector "input[type='file']"
  end

  # AAA semantic tokens (the design-token guarantee), not raw Tailwind.
  # File inputs are state-independent (no NORMAL/ERROR swap) — styling lives in BASE.
  # Chained classes collapse the token set into single assertions.
  def test_renders_base_aaa_tokens
    render_inline(UI::FileInputComponent.new)

    assert_selector "input.block.w-full.text-text-body"
  end

  def test_renders_file_button_aaa_tokens
    render_inline(UI::FileInputComponent.new)

    assert_selector "input.file\\:bg-interactive.file\\:text-text-on-interactive.hover\\:file\\:bg-interactive-hover"
  end

  # A disabled file input is visually distinct.
  def test_renders_disabled_styling
    render_inline(UI::FileInputComponent.new)

    assert_selector "input.disabled\\:cursor-not-allowed.disabled\\:opacity-50"
  end

  # invalid: drives a visible danger ring, not just aria-invalid.
  def test_carries_a_danger_ring_token_for_invalid
    render_inline(UI::FileInputComponent.new)

    assert_selector "input.aria-invalid\\:ring-danger"
  end

  def test_accept_passes_through
    render_inline(UI::FileInputComponent.new(accept: "image/*"))

    assert_selector "input[type='file'][accept='image/*']"
  end

  def test_no_accept_by_default
    render_inline(UI::FileInputComponent.new)

    assert_no_selector "input[accept]"
  end

  def test_multiple_passes_through
    render_inline(UI::FileInputComponent.new(multiple: true))

    assert_selector "input[type='file'][multiple]"
  end

  def test_not_multiple_by_default
    render_inline(UI::FileInputComponent.new)

    assert_no_selector "input[multiple]"
  end

  # invalid: drives the server-validation-driven aria-invalid posture.
  def test_invalid_sets_aria_invalid
    render_inline(UI::FileInputComponent.new(invalid: true))

    assert_selector "input[type='file'][aria-invalid='true']"
  end

  def test_not_invalid_by_default
    render_inline(UI::FileInputComponent.new)

    assert_no_selector "input[aria-invalid='true']"
  end

  def test_required_sets_required_and_aria_required
    render_inline(UI::FileInputComponent.new(required: true))

    assert_selector "input[type='file'][required]"
    assert_selector "input[aria-required='true']"
  end

  def test_not_required_by_default
    render_inline(UI::FileInputComponent.new)

    assert_no_selector "input[required]"
    assert_no_selector "input[aria-required='true']"
  end

  def test_describedby_sets_aria_describedby
    render_inline(UI::FileInputComponent.new(describedby: "avatar_error"))

    assert_selector "input[type='file'][aria-describedby='avatar_error']"
  end

  def test_no_describedby_by_default
    render_inline(UI::FileInputComponent.new)

    assert_no_selector "input[aria-describedby]"
  end
end
