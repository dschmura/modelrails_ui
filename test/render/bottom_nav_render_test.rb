# frozen_string_literal: true

require "render_test_helper"

load_component "bottom_nav", "bottom_nav_component.rb.tt"

# STRUCTURE-only render specs. BottomNav is a fixed <nav> landmark holding a row of
# link items; each item carries the AAA focus-ring and the active one gets
# aria-current="page". The app 0b proves AAA contrast in a real browser; here we
# assert the scaffolding + the landmark/focus contract.
class BottomNavRenderTest < ViewComponent::TestCase
  def items
    [
      {label: "Home", href: "/", active: true},
      {label: "Search", href: "/search"},
      {label: "Profile", href: "/profile"}
    ]
  end

  def render_basic(**opts)
    render_inline(UI::BottomNavComponent.new(items: items, **opts))
  end

  def test_renders_a_fixed_nav_bar
    render_basic

    assert_selector "nav.fixed.bottom-0.bg-surface-raised"
  end

  # The <nav> landmark gets an accessible name (i18n default) so it's distinguishable
  # from other navs on the page.
  def test_nav_landmark_has_the_i18n_default_accessible_name
    render_basic

    assert_selector "nav[aria-label='Bottom navigation']"
  end

  def test_custom_label_names_the_nav
    render_basic(label: "Primary")

    assert_selector "nav[aria-label='Primary']"
  end

  def test_items_carry_the_focus_ring_and_active_gets_aria_current
    render_basic

    assert_selector "a.focus-ring[href='/'][aria-current='page']", text: "Home"
    assert_selector "a.focus-ring[href='/search']", text: "Search"
    assert_no_selector "a[href='/search'][aria-current]"
  end

  def test_active_item_uses_the_interactive_token
    render_basic

    assert_selector "a.text-interactive[href='/']", text: "Home"
    assert_selector "a.text-text-muted[href='/search']", text: "Search"
  end

  def test_renders_an_optional_icon_string
    render_inline(
      UI::BottomNavComponent.new(
        items: [{label: "Home", href: "/", icon: "<svg data-icon='home'></svg>"}]
      )
    )

    assert_selector "a[href='/'] svg[data-icon='home']"
  end

  # Regression guard: the ring anti-pattern must never come back.
  def test_no_box_shadow_ring_or_outline_none
    render_basic
    html = page.native.to_html

    refute_includes html, "focus-visible:ring-"
    refute_includes html, "outline-none"
  end

  # html_attrs pass through onto the root <nav>.
  def test_passes_through_html_attrs_onto_the_root
    render_inline(
      UI::BottomNavComponent.new(items: items, id: "app-bottom-nav", data: {testid: "bn"})
    )

    assert_selector "nav#app-bottom-nav[data-testid='bn']"
  end
end
