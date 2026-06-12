# frozen_string_literal: true

require "render_test_helper"
load_component "mega_menu", "mega_menu_component.rb.tt"

# STRUCTURE-only render specs. The `mega-menu` controller's BEHAVIOR (open/close,
# outside-click dismissal, aria-expanded sync) is proven by the app 0b browser spec —
# the render harness cannot exercise JS, so here we assert the static scaffolding the
# controller drives, the disclosure/nav semantics, and the AAA focus-ring contract.
#
# Semantics note: a mega menu is a disclosure revealing a <nav> region of links, NOT
# the WAI-ARIA `menu` pattern — so there is intentionally no role=menu / role=menuitem
# and no shared `menu` controller here (unlike dropdown_menu/menubar).
class MegaMenuRenderTest < ViewComponent::TestCase
  def render_menu(**opts)
    render_inline(UI::MegaMenuComponent.new(label: "Products", **opts)) do |m|
      m.with_column(heading: "Platform", items: [
        {title: "Overview", description: "Tour the product", href: "/overview"},
        {title: "Pricing", href: "/pricing"}
      ])
      m.with_column(heading: "Resources", items: [
        {title: "Docs", href: "/docs"}
      ])
    end
  end

  def test_wrapper_wires_the_mega_menu_controller_and_outside_click
    render_menu(id: "mm1")

    assert_selector "div#mm1[data-controller='mega-menu']" \
                    "[data-action~='click@document->mega-menu#closeOnClickOutside']",
      visible: :all
  end

  # Disclosure button: real <button> with haspopup, synced aria-expanded, and
  # aria-controls pointing at the panel.
  def test_trigger_is_a_disclosure_button_with_aria_wiring
    render_menu(id: "mm2")

    assert_selector "button[type='button'][aria-haspopup='true'][aria-expanded='false']" \
                    "[aria-controls='mm2-panel'][data-mega-menu-target='trigger']" \
                    "[data-action~='click->mega-menu#toggle']",
      text: "Products", visible: :all
  end

  # The trigger label IS the accessible name — no separate i18n string needed, but the
  # trigger must carry the offset focus-ring (not a box-shadow ring).
  def test_trigger_carries_the_focus_ring
    render_menu

    assert_selector "button.focus-ring[aria-haspopup='true']", text: "Products", visible: :all
  end

  # The revealed panel is a named <nav> landmark (named by the trigger label) and is
  # hidden until disclosed, wired as the controller's panel target + aria-controls target.
  def test_panel_is_a_named_nav_landmark_and_hidden
    render_menu(id: "mm3")

    assert_selector "nav#mm3-panel[aria-label='Products'][hidden]" \
                    "[data-mega-menu-target='panel']",
      visible: :all
  end

  def test_columns_render_their_headings
    render_menu

    assert_selector "p", text: "Platform", visible: :all
    assert_selector "p", text: "Resources", visible: :all
  end

  def test_columns_render_link_items
    render_menu

    assert_selector "a[href='/overview']", text: "Overview", visible: :all
    assert_selector "a[href='/docs']", text: "Docs", visible: :all
  end

  # Nav links carry the AAA focus-ring (they are ordinary anchors, not role=menuitem).
  def test_link_items_carry_the_focus_ring
    render_menu

    assert_selector "a.focus-ring[href='/overview']", text: "Overview", visible: :all
  end

  # Semantics guard: this is a disclosure+nav, NOT a role=menu. The menu roles must
  # never leak in.
  def test_does_not_use_the_menu_role_pattern
    render_menu

    assert_no_selector "[role='menu']", visible: :all
    assert_no_selector "[role='menuitem']", visible: :all
  end

  # The chevron is decorative.
  def test_chevron_is_decorative
    render_menu

    assert_selector "svg[aria-hidden='true'][data-mega-menu-target='chevron']", visible: :all
  end

  # Regression guard: the ring anti-pattern must never come back.
  def test_no_box_shadow_ring_or_outline_none
    render_menu
    html = page.native.to_html

    refute_includes html, "focus-visible:ring-"
    refute_includes html, "outline-none"
  end

  def test_explicit_cols_overrides_the_auto_grid
    render_menu(cols: 4)

    assert_selector "div.grid-cols-4", visible: :all
  end

  def test_requires_a_label
    assert_raises(ArgumentError) { UI::MegaMenuComponent.new }
  end

  # html_attrs pass through onto the root <div>, and a caller class merges without
  # clobbering the positioning context.
  def test_passes_through_html_attrs_and_merges_class
    render_inline(UI::MegaMenuComponent.new(label: "Products", class: "mt-4", data: {testid: "mm"})) do |m|
      m.with_column(items: [{title: "Docs", href: "/docs"}])
    end

    assert_selector "div.relative.mt-4[data-testid='mm']", visible: :all
  end
end
