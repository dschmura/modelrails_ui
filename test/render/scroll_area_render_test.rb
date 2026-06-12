# frozen_string_literal: true

require "render_test_helper"
load_component "scroll_area", "scroll_area_component.rb.tt"

class ScrollAreaRenderTest < ViewComponent::TestCase
  # WCAG 2.1.1: a focusable scroll region is a tab stop and is announced.
  def test_focusable_region_is_a_named_tab_stop
    render_inline(UI::ScrollAreaComponent.new(aria_label: "Release notes")) { "content" }

    assert_selector "div[tabindex='0'][role='region'][aria-label='Release notes']"
  end

  # A focusable region needs a visible focus indicator: the focus-ring utility.
  def test_focusable_region_has_focus_ring
    render_inline(UI::ScrollAreaComponent.new(aria_label: "Log")) { "content" }

    assert_selector "div.focus-ring"
  end

  def test_accepts_aria_labelledby_as_the_accessible_name
    render_inline(UI::ScrollAreaComponent.new(aria_labelledby: "log-heading")) { "content" }

    assert_selector "div[role='region'][aria-labelledby='log-heading']"
    assert_no_selector "div[aria-label]"
  end

  # A focusable region with no name is the documented anti-pattern — fail loud.
  def test_fails_loud_without_an_accessible_name
    assert_raises(ArgumentError) do
      render_inline(UI::ScrollAreaComponent.new) { "content" }
    end
  end

  # focusable: false opts out of the tab stop (content is itself keyboard-reachable).
  def test_focusable_false_is_not_a_tab_stop_and_has_no_focus_ring
    render_inline(UI::ScrollAreaComponent.new(focusable: false)) { "content" }

    assert_no_selector "div[tabindex]"
    assert_no_selector "div.focus-ring"
  end

  def test_default_orientation_uses_vertical_overflow
    render_inline(UI::ScrollAreaComponent.new(aria_label: "Log")) { "content" }

    assert_selector "div.overflow-y-auto.max-h-72"
  end

  def test_horizontal_orientation_uses_x_overflow
    render_inline(UI::ScrollAreaComponent.new(orientation: :horizontal, aria_label: "Gallery")) { "content" }

    assert_selector "div.overflow-x-auto"
  end

  # fail loud on an unknown orientation rather than silently defaulting.
  def test_fails_loud_on_unknown_orientation
    assert_raises(ArgumentError) do
      render_inline(UI::ScrollAreaComponent.new(orientation: :diagonal, aria_label: "x")) { "c" }
    end
  end

  # AAA semantic scrollbar tokens (token-driven, never raw hex).
  def test_renders_with_aaa_scrollbar_tokens
    render_inline(UI::ScrollAreaComponent.new(aria_label: "Log")) { "content" }

    assert_selector "div.\\[\\&\\:\\:-webkit-scrollbar-thumb\\]\\:bg-border"
    assert_selector "div.\\[scrollbar-color\\:var\\(--color-border\\)_transparent\\]"
  end

  def test_merges_caller_classes
    render_inline(UI::ScrollAreaComponent.new(aria_label: "Log", class: "rounded-lg border")) { "content" }

    assert_selector "div.rounded-lg.border"
  end
end
