# frozen_string_literal: true

require "render_test_helper"
require "securerandom"
load_component "tooltip", "tooltip_component.rb.tt"

class TooltipRenderTest < ViewComponent::TestCase
  def render_tooltip(**opts)
    render_inline(UI::TooltipComponent.new(text: "Saved", **opts)) { "Status" }
  end

  def test_wrapper_is_focusable_and_describes_the_bubble
    render_tooltip(id: "t1")

    assert_selector "span.group\\/tooltip[tabindex='0'][aria-describedby='t1'][data-controller='floating']", visible: :all
    assert_selector "span[data-action~='keydown.esc->floating#dismiss']", visible: :all
    assert_selector "span[data-action~='mouseleave->floating#clearDismissed']", visible: :all
  end

  def test_wrapper_wires_focusout_to_clear_dismissed
    render_tooltip(id: "t1")

    assert_selector "span[data-action~='focusout->floating#clearDismissed']", visible: :all
  end

  def test_bubble_is_a_tooltip_role_with_the_referenced_id
    render_tooltip(id: "t2", text: "Copied to clipboard")

    assert_selector "span#t2[role='tooltip']", text: "Copied to clipboard", visible: :all
  end

  # NAMED group variants (`group/tooltip`), not the bare `group-*:` forms — the
  # unnamed variants match ANY `.group` ancestor, so a tooltip nested inside a
  # grouped container (e.g. a `.group` <details>) raised every bubble whenever
  # hover/focus sat anywhere inside that ancestor.
  def test_bubble_shows_on_hover_and_focus_and_force_hides_when_dismissed
    render_tooltip

    assert_selector "[role='tooltip'].group-hover\\/tooltip\\:opacity-100", visible: :all
    assert_selector "[role='tooltip'].group-focus-within\\/tooltip\\:opacity-100", visible: :all
    assert_selector "[role='tooltip'].group-data-\\[dismissed\\]\\/tooltip\\:opacity-0\\!", visible: :all
  end

  # Public API for the documented "describe an existing interactive control"
  # pattern: the caller builds its own group/tooltip wrapper + aria-describedby
  # and reuses the bubble classes exactly.
  def test_bubble_classes_exposes_the_bubble_for_caller_built_wrappers
    classes = UI::TooltipComponent.bubble_classes(side: :bottom)

    assert_includes classes, "group-hover/tooltip:opacity-100"
    assert_includes classes, "group-focus-within/tooltip:opacity-100"
    assert_includes classes, "mt-2"
  end

  def test_bubble_classes_defaults_to_top_and_fails_loud_on_unknown_side
    assert_includes UI::TooltipComponent.bubble_classes, "mb-2"
    assert_raises(KeyError) { UI::TooltipComponent.bubble_classes(side: :sideways) }
  end

  def test_corner_placement_maps_to_a_position_area_corner
    render_tooltip(side: :top_right)

    assert_selector "[role='tooltip']",
      class: ["supports-[position-area:bottom]:[position-area:top_right]"], visible: :all
  end

  def test_fail_loud_on_unknown_side
    error = assert_raises(ArgumentError) { UI::TooltipComponent.new(text: "x", side: :sideways) }
    assert_match(/unknown side/, error.message)
  end
end
