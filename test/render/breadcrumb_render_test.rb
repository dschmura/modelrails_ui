# frozen_string_literal: true

require "render_test_helper"
load_component "breadcrumb", "breadcrumb_component.rb.tt"

# STRUCTURE-only render specs. Breadcrumb is a static nav (no JS); the app 0b proves it renders
# + axe-AAA in a real browser. Here we assert the landmark + crumb scaffolding.
class BreadcrumbRenderTest < ViewComponent::TestCase
  def render_crumbs
    render_inline(UI::BreadcrumbComponent.new(items: [
      {label: "Home", href: "/"},
      {label: "Library", href: "/library"},
      {label: "Data"}
    ]))
  end

  def test_nav_is_a_breadcrumb_landmark_with_an_ordered_list
    render_crumbs

    assert_selector "nav[aria-label='Breadcrumb'] ol", visible: :all
  end

  def test_last_item_is_the_current_page
    render_crumbs

    assert_selector "[aria-current='page']", text: "Data", visible: :all
    assert_no_selector "a", text: "Data", visible: :all
  end

  def test_non_last_items_are_links_with_decorative_separators
    render_crumbs

    assert_selector "a[href='/']", text: "Home", visible: :all
    assert_selector "a[href='/library']", text: "Library", visible: :all
    assert_selector "span[aria-hidden='true']", minimum: 2, visible: :all
  end

  def test_label_can_be_overridden_for_i18n
    render_inline(UI::BreadcrumbComponent.new(label: "You are here", items: [{label: "Home", href: "/"}, {label: "X"}]))

    assert_selector "nav[aria-label='You are here']", visible: :all
  end

  # "Linked for some viewers, plain for others": a non-last crumb WITHOUT an
  # href renders as plain text (never a dead <a>), so a policy-gated crumb can
  # drop its link without leaving the trail.
  def test_hrefless_non_last_item_renders_as_plain_text
    render_inline(UI::BreadcrumbComponent.new(items: [
      {label: "Building"},
      {label: "Room 2100"}
    ]))

    assert_selector "li > span.text-text-muted", text: "Building", visible: :all
    assert_no_selector "a", visible: :all
    assert_selector "[aria-current='page']", text: "Room 2100", visible: :all
  end

  # max_items collapses the MIDDLE of a long trail. The dropped crumbs go for everyone —
  # no visually-hidden copy — so the trail never claims a depth the reader cannot reach.
  def long_trail
    [
      {label: "Home", href: "/"},
      {label: "Projects", href: "/projects"},
      {label: "Apollo", href: "/projects/1"},
      {label: "Write the spec"}
    ]
  end

  def test_trail_under_the_limit_is_untouched
    render_inline(UI::BreadcrumbComponent.new(items: long_trail, max_items: 4))

    assert_no_selector "[data-slot='breadcrumb-ellipsis']", visible: :all
  end

  # max_items: 3 on a 4-crumb trail keeps the root plus the last two, so exactly the
  # second crumb is dropped.
  def test_long_trail_collapses_its_middle
    render_inline(UI::BreadcrumbComponent.new(items: long_trail, max_items: 3))

    assert_selector "[data-slot='breadcrumb-ellipsis'][aria-hidden='true']", count: 1, visible: :all
    assert_no_link "Projects"
    assert_link "Apollo"
  end

  def test_collapsed_trail_keeps_root_and_current_page
    render_inline(UI::BreadcrumbComponent.new(items: long_trail, max_items: 2))

    assert_link "Home"
    assert_selector "[aria-current='page']", text: "Write the spec", visible: :all
  end

  def test_max_items_below_two_raises
    error = assert_raises(ArgumentError) { UI::BreadcrumbComponent.new(items: long_trail, max_items: 1) }

    assert_match(/max_items/, error.message)
  end
end
