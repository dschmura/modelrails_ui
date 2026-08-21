# frozen_string_literal: true

require "render_test_helper"
load_component "sidebar", "sidebar_component.rb.tt"

# STRUCTURE-only render specs. Sidebar is an <aside> rail with a named <nav>
# landmark; the toggle/items carry the AAA focus-ring. The app 0b proves AAA in a
# real browser; here we assert the scaffolding + the landmark/focus contract.
class SidebarRenderTest < ViewComponent::TestCase
  def render_basic(**opts)
    render_inline(UI::SidebarComponent.new(**opts)) do |s|
      s.with_item(label: "Dashboard", href: "/", icon: :home, active: true)
      s.with_item(label: "Settings", href: "/settings", icon: :settings)
    end
  end

  def test_renders_an_aside_rail_wired_to_the_sidebar_controller
    render_basic

    assert_selector "aside[data-controller='sidebar'][data-collapsed='false']"
  end

  # The <nav> landmark gets an accessible name (i18n default) so it's distinguishable
  # from other navs on the page.
  def test_nav_landmark_has_the_i18n_default_accessible_name
    render_basic

    assert_selector "nav[aria-label='Sidebar']"
  end

  def test_custom_label_names_the_nav
    render_basic(label: "Main menu")

    assert_selector "nav[aria-label='Main menu']"
  end

  # The toggle is i18n-labelled and carries the offset focus-ring (not a box-shadow ring).
  def test_toggle_button_is_i18n_labelled_and_carries_the_focus_ring
    render_basic

    assert_selector "button.focus-ring[aria-label='Toggle sidebar'][data-action='click->sidebar#toggle']"
  end

  def test_items_carry_the_focus_ring_and_active_gets_aria_current
    render_basic

    assert_selector "a.focus-ring[href='/'][aria-current='page']", text: "Dashboard"
    assert_selector "a.focus-ring[href='/settings']", text: "Settings"
    assert_no_selector "a[href='/settings'][aria-current]"
  end

  # Regression guard: the ring anti-pattern must never come back.
  def test_no_box_shadow_ring_or_outline_none
    render_basic
    html = page.native.to_html

    refute_includes html, "focus-visible:ring-"
    refute_includes html, "outline-none"
  end

  def test_collapsed_state_renders_on_the_rail
    render_basic(collapsed: true)

    assert_selector "aside[data-collapsed='true']"
  end

  def test_renders_groups_with_labels
    render_inline(UI::SidebarComponent.new) do |s|
      s.with_group(label: "Main") do |g|
        g.with_item(label: "Dashboard", href: "/")
      end
    end

    assert_selector "p", text: "Main"
    assert_selector "nav a[href='/']", text: "Dashboard"
  end

  # data-collapsed drives the CSS and is invisible to assistive tech; aria-expanded is
  # the only representation of collapse state a screen reader can perceive.
  def test_toggle_reports_expanded_state
    render_basic

    assert_selector "button[aria-label='Toggle sidebar'][aria-expanded='true']"
  end

  def test_toggle_reports_collapsed_state
    render_basic(collapsed: true)

    assert_selector "button[aria-label='Toggle sidebar'][aria-expanded='false']"
  end

  # aria-controls has to resolve to a real element, or it names nothing.
  def test_toggle_controls_the_nav_it_collapses
    render_basic(id: "app-sidebar")

    assert_selector "button[aria-controls='app-sidebar-nav']"
    assert_selector "nav#app-sidebar-nav"
  end

  # The rail hint is decorative BY CONSTRUCTION: the item's label is clipped to width 0
  # but stays in the a11y tree, so the link already has its name. Announcing the bubble
  # too would name every item twice.
  def test_rail_hint_is_hidden_from_assistive_technology
    render_basic

    assert_selector "nav a [data-slot='rail-tooltip'][aria-hidden='true']", visible: :all, count: 2
  end

  # The bubble is anchor-positioned, so each item's anchor-name must be unique or every
  # hint tethers to the same item.
  def test_each_item_anchors_its_own_hint
    render_basic
    anchors = page.all("nav a", visible: :all).map { |a| a[:style] }

    assert_equal 2, anchors.uniq.size
  end

  def test_persistence_is_on_by_default_and_opt_outable
    render_basic

    assert_selector "aside[data-sidebar-remember-value='true']"

    render_basic(remember: false)

    assert_selector "aside[data-sidebar-remember-value='false']"
  end

  # html_attrs pass through onto the root <aside>.
  def test_passes_through_html_attrs_onto_the_root
    render_inline(UI::SidebarComponent.new(id: "app-sidebar", data: {testid: "sb"})) do |s|
      s.with_item(label: "X", href: "/x")
    end

    assert_selector "aside#app-sidebar[data-testid='sb']"
  end
end
