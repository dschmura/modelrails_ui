# frozen_string_literal: true

require "render_test_helper"
load_component "skeleton", "skeleton_component.rb.tt"

class SkeletonRenderTest < ViewComponent::TestCase
  # Decorative loading placeholder — must be hidden so SR doesn't announce empty boxes.
  def test_is_aria_hidden
    render_inline(UI::SkeletonComponent.new)

    assert_selector "div[aria-hidden='true']", visible: :all
  end

  def test_pulses_and_respects_reduced_motion
    render_inline(UI::SkeletonComponent.new)

    assert_selector "div.animate-pulse.motion-reduce\\:animate-none", visible: :all
  end

  def test_renders_with_aaa_surface_token
    render_inline(UI::SkeletonComponent.new)

    assert_selector "div.bg-surface-sunken", visible: :all
  end

  def test_merges_caller_classes
    render_inline(UI::SkeletonComponent.new(class: "h-4 w-48"))

    assert_selector "div.h-4.w-48", visible: :all
  end
end
