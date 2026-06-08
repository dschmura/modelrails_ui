# frozen_string_literal: true

require "render_test_helper"
require "securerandom"
load_component "navbar", "navbar_component.rb.tt"

# STRUCTURE-only render specs. The disclosure behavior (toggle, aria-expanded sync, Escape +
# focus return, outside-click) is proven by the app 0b browser spec at a mobile viewport — the
# render harness cannot exercise JS, so here we assert the static scaffolding.
class NavbarRenderTest < ViewComponent::TestCase
  def render_navbar
    render_inline(UI::NavbarComponent.new(brand: "Acme", items: [
      {label: "Home", href: "/", active: true},
      {label: "Pricing", href: "/pricing"}
    ]))
  end

  def test_nav_is_a_landmark_wired_to_the_navbar_controller
    render_navbar

    assert_selector "nav[aria-label][data-controller='navbar']" \
                    "[data-action~='keydown->navbar#closeOnEscape']" \
                    "[data-action~='click@document->navbar#closeOnClickOutside']", visible: :all
  end

  def test_hamburger_is_a_disclosure_button
    render_navbar

    assert_selector "button[type='button'][aria-expanded='false'][aria-controls]" \
                    "[data-navbar-target='toggle'][data-action~='click->navbar#toggle'][aria-label]",
      visible: :all
  end

  def test_hamburger_controls_the_hidden_mobile_menu_panel
    render_navbar

    button = page.find("button[data-navbar-target='toggle']", visible: :all)
    menu_id = button["aria-controls"]

    assert_selector "div##{menu_id}[data-navbar-target='menu'][hidden]", visible: :all
  end

  def test_active_link_is_aria_current_page
    render_navbar

    assert_selector "a[aria-current='page']", text: "Home", visible: :all
    assert_no_selector "a[aria-current='page']", text: "Pricing", visible: :all
  end

  def test_caller_data_merges_without_clobbering_the_controller
    render_inline(UI::NavbarComponent.new(items: [{label: "Home", href: "/"}], data: {turbo_frame: "f"}))

    assert_selector "nav[data-controller='navbar'][data-turbo-frame='f']", visible: :all
  end

  def test_nav_label_can_be_overridden
    render_inline(UI::NavbarComponent.new(label: "Primary", items: [{label: "Home", href: "/"}]))

    assert_selector "nav[aria-label='Primary']", visible: :all
  end
end
