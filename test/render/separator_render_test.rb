# frozen_string_literal: true

require "render_test_helper"
load_component "separator", "separator_component.rb.tt"

class SeparatorRenderTest < ViewComponent::TestCase
  def test_decorative_by_default_uses_role_none
    render_inline(UI::SeparatorComponent.new)

    assert_selector "div[role='none']", visible: :all
  end

  # aria-orientation is invalid on role="none" — it must NOT be emitted on a
  # decorative separator.
  def test_decorative_omits_aria_orientation
    render_inline(UI::SeparatorComponent.new)

    assert_no_selector "div[aria-orientation]", visible: :all
  end

  def test_semantic_uses_role_separator_with_aria_orientation
    render_inline(UI::SeparatorComponent.new(decorative: false))

    assert_selector "div[role='separator'][aria-orientation='horizontal']", visible: :all
  end

  def test_vertical_semantic_announces_vertical_orientation
    render_inline(UI::SeparatorComponent.new(orientation: :vertical, decorative: false))

    assert_selector "div[role='separator'][aria-orientation='vertical']", visible: :all
  end

  def test_horizontal_orientation_classes
    render_inline(UI::SeparatorComponent.new)

    assert_selector "div.bg-border.h-px.w-full", visible: :all
  end

  def test_vertical_orientation_classes
    render_inline(UI::SeparatorComponent.new(orientation: :vertical))

    assert_selector "div.bg-border.h-full.w-px", visible: :all
  end

  def test_merges_caller_classes
    render_inline(UI::SeparatorComponent.new(class: "my-4"))

    assert_selector "div.my-4", visible: :all
  end
end
