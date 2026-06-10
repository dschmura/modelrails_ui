# frozen_string_literal: true

require "render_test_helper"
load_component "button_group", "button_group_component.rb.tt"

# STRUCTURE-only render specs. ButtonGroup is a purely presentational
# `role="group"` wrapper: it owns no state/JS/keyboard — it only collapses the
# inner corners and overlaps borders so its children read as one segmented bar.
# The app 0b proves the rendered bar axe-AAA in a real browser.
class ButtonGroupRenderTest < ViewComponent::TestCase
  def render_group(**kwargs, &block)
    block ||= proc { "X" }
    render_inline(UI::ButtonGroupComponent.new(**kwargs), &block)
  end

  def test_renders_a_role_group_div
    render_group

    assert_selector "div[role='group']"
  end

  # The flex layout + rounded outer shell of the segmented shell.
  def test_carries_the_layout_base_classes
    render_group

    assert_selector "div.inline-flex.rounded-md.shadow-sm"
  end

  # The rounded-adjacency rules are what make the children read as one control:
  # neutralise every child's corners, then re-round the bar's two outer edges and
  # overlap the shared borders. These classes contain `&`/`[`/`:`, so they must be
  # matched as substrings — and all four must live on the same root.
  def test_carries_the_corner_adjacency_base_classes
    render_group

    assert_selector "div[class*='[&>*]:rounded-none']" \
                    "[class*='[&>*:first-child]:rounded-l-md']" \
                    "[class*='[&>*:last-child]:rounded-r-md']" \
                    "[class*='[&>*:not(:first-child)]:-ml-px']"
  end

  # Arbitrary content children render inside the wrapper.
  def test_renders_content_children_inside
    render_group do
      "<button>One</button><button>Two</button>".html_safe
    end

    assert_selector "div[role='group'] > button", text: "One"
    assert_selector "div[role='group'] > button", text: "Two"
  end

  # html_attrs pass through onto the root, matching the sibling components.
  def test_passes_through_html_attrs_onto_the_root
    render_group(id: "view-toggle", data: {testid: "group"})

    assert_selector "div#view-toggle[role='group'][data-testid='group']"
  end

  # A caller-supplied class merges onto the root WITHOUT clobbering the BASE.
  def test_merges_caller_class_onto_the_root_preserving_base
    render_group(class: "mt-4")

    assert_selector "div.mt-4.inline-flex.shadow-sm"
    assert_selector "div[class*='[&>*]:rounded-none']"
  end

  # `aria_label:` gives the group an accessible name when the caller supplies one.
  def test_aria_label_emits_an_accessible_name_when_given
    render_group(aria_label: "View mode")

    assert_selector "div[role='group'][aria-label='View mode']"
  end

  # It is optional — absent by default (a group is often labelled by context).
  def test_aria_label_is_absent_by_default
    render_group

    assert_no_selector "div[role='group'][aria-label]"
  end
end
