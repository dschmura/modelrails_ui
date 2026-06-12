# frozen_string_literal: true

require "render_test_helper"
load_component "aspect_ratio", "aspect_ratio_component.rb.tt"

class AspectRatioRenderTest < ViewComponent::TestCase
  def test_renders_the_ratio_wrapper_with_slotted_content
    render_inline(UI::AspectRatioComponent.new) { "<img src='/x.jpg' alt='x'>".html_safe }

    assert_selector "div img[src='/x.jpg']"
  end

  # AAA semantic tokens / layout-only utilities — no raw color, no off-system class.
  # The wrapper is presentational, so the only base utility is the clip that keeps
  # slotted media inside the ratio box.
  def test_renders_with_layout_only_base_classes
    render_inline(UI::AspectRatioComponent.new) { "content" }

    assert_selector "div.overflow-hidden"
  end

  # Non-interactive by contract — a layout wrapper is never a focus/pointer target,
  # so it carries no role, no tabindex, and no focus ring.
  def test_is_a_presentational_wrapper
    render_inline(UI::AspectRatioComponent.new) { "content" }

    assert_no_selector "div[role]"
    assert_no_selector "div[tabindex]"
  end

  def test_applies_the_default_square_ratio
    render_inline(UI::AspectRatioComponent.new) { "content" }

    assert_selector "div[style*='aspect-ratio: 1']"
  end

  def test_applies_a_custom_ratio
    render_inline(UI::AspectRatioComponent.new(ratio: "16 / 9")) { "content" }

    assert_selector "div[style*='aspect-ratio: 16 / 9']"
  end

  def test_merges_caller_classes
    render_inline(UI::AspectRatioComponent.new(class: "mt-2")) { "content" }

    assert_selector "div.overflow-hidden.mt-2"
  end
end
