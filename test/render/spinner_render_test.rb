# frozen_string_literal: true

require "render_test_helper"
load_component "spinner", "spinner_component.rb.tt"

class SpinnerRenderTest < ViewComponent::TestCase
  def test_has_status_role_with_sr_only_loading_text
    render_inline(UI::SpinnerComponent.new)

    assert_selector "span[role='status']", visible: :all
    assert_selector "span.sr-only", text: "Loading…", visible: :all
  end

  def test_default_size
    render_inline(UI::SpinnerComponent.new)

    assert_selector "span.size-6", visible: :all
  end

  def test_small_size
    render_inline(UI::SpinnerComponent.new(size: :sm))

    assert_selector "span.size-4", visible: :all
  end

  def test_large_size
    render_inline(UI::SpinnerComponent.new(size: :lg))

    assert_selector "span.size-10", visible: :all
  end

  # A spinner must spin — animate-spin is required (and intentionally NOT
  # motion-reduce-suppressed).
  def test_renders_spin_and_border_tokens
    render_inline(UI::SpinnerComponent.new)

    assert_selector "span.animate-spin.rounded-full.border-2.border-current.border-t-transparent", visible: :all
  end

  def test_merges_caller_classes
    render_inline(UI::SpinnerComponent.new(class: "text-interactive"))

    assert_selector "span.text-interactive", visible: :all
  end
end
