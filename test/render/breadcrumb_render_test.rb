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
end
