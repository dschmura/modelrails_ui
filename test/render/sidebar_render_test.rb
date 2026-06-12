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

  # html_attrs pass through onto the root <aside>.
  def test_passes_through_html_attrs_onto_the_root
    render_inline(UI::SidebarComponent.new(id: "app-sidebar", data: {testid: "sb"})) do |s|
      s.with_item(label: "X", href: "/x")
    end

    assert_selector "aside#app-sidebar[data-testid='sb']"
  end
end
