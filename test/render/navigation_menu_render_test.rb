# frozen_string_literal: true

require "render_test_helper"
load_component "navigation_menu", "navigation_menu_component.rb.tt"

# STRUCTURE-only render specs. Navigation menu is a named <nav> landmark whose
# flyout triggers are real <button>s implementing the APG *disclosure* pattern
# (aria-expanded synced by the component-owned `navigation-menu` controller +
# aria-controls → an id'd panel). The links/triggers carry the AAA focus-ring.
# The app 0b proves AAA contrast in a real browser; here we assert the
# scaffolding + the landmark/disclosure/focus contract.
class NavigationMenuRenderTest < ViewComponent::TestCase
  def render_basic(**opts)
    render_inline(UI::NavigationMenuComponent.new(**opts)) do |nav|
      nav.with_item(label: "Home", href: "/", active: true)
      nav.with_item(label: "Docs", href: "/docs")
      nav.with_item(label: "Products") do
        "<a href='/a' class='#{UI::NavigationMenuComponent::PANEL_LINK}'>A</a>".html_safe
      end
    end
  end

  def test_root_is_a_named_nav_landmark_with_the_i18n_default
    render_basic

    assert_selector "nav[aria-label='Main'] > ul"
  end

  def test_custom_label_names_the_nav
    render_basic(label: "Primary")

    assert_selector "nav[aria-label='Primary']"
  end

  # Plain links carry the offset focus-ring (not a box-shadow ring); active → aria-current.
  def test_links_carry_the_focus_ring_and_active_gets_aria_current
    render_basic

    assert_selector "a.focus-ring[href='/'][aria-current='page']", text: "Home"
    assert_selector "a.focus-ring[href='/docs']", text: "Docs"
    assert_no_selector "a[href='/docs'][aria-current]"
  end

  # The disclosure trigger is a real <button> with the focus-ring and synced aria-expanded.
  def test_flyout_trigger_is_a_button_with_focus_ring_and_aria_expanded
    render_basic

    assert_selector "button.focus-ring[type='button'][aria-expanded='false'][aria-haspopup='true']",
      text: "Products"
    assert_selector "button[data-navigation-menu-target='trigger']", text: "Products"
  end

  # Disclosure wiring: the trigger's aria-controls points at its id'd, hidden flyout panel.
  def test_trigger_aria_controls_points_at_its_hidden_flyout_panel
    render_basic

    trigger = page.find("button[aria-haspopup='true']")
    panel_id = trigger["aria-controls"]

    refute_nil panel_id
    assert_selector "div##{panel_id}[data-navigation-menu-target='content']", visible: :all
  end

  # The trigger wires the component-owned `navigation-menu` controller (NOT the shared `menu`).
  def test_trigger_item_wires_the_navigation_menu_controller
    render_basic

    assert_selector "div[data-controller='navigation-menu']"
    assert_no_selector "[data-controller='menu']"
  end

  # The chevron is decorative — kept out of the accessibility tree.
  def test_chevron_is_decorative
    render_basic

    assert_selector "button[aria-haspopup='true'] svg[aria-hidden='true']"
  end

  # align: drives the list justification via a fail-loud enum.
  def test_align_drives_list_justification
    render_basic(align: :end)

    assert_selector "ul[class*='justify-end']"
  end

  def test_unknown_align_raises
    assert_raises(ArgumentError) do
      render_inline(UI::NavigationMenuComponent.new(align: :bogus))
    end
  end

  # Regression guard: the box-shadow ring / outline-none anti-pattern must never come back.
  def test_no_box_shadow_ring_or_outline_none
    render_basic
    html = page.native.to_html

    refute_includes html, "focus-visible:ring-"
    refute_includes html, "outline-none"
  end

  # html_attrs pass through onto the root <nav>.
  def test_passes_through_html_attrs_onto_the_root
    render_inline(UI::NavigationMenuComponent.new(id: "site-nav", data: {testid: "nav"})) do |nav|
      nav.with_item(label: "Home", href: "/")
    end

    assert_selector "nav#site-nav[data-testid='nav']"
  end

  # A caller-supplied class merges onto the root without clobbering the layout tokens.
  def test_merges_caller_class_onto_the_root
    render_inline(UI::NavigationMenuComponent.new(class: "mt-4")) do |nav|
      nav.with_item(label: "Home", href: "/")
    end

    assert_selector "nav.mt-4[class*='max-w-max']"
  end
end
