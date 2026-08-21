# frozen_string_literal: true

require "system_test_helper"
load_component "sidebar", "sidebar_component.rb.tt"

# What the controller keeps in sync once it runs. Collapse state has three
# representations — data-collapsed for the CSS, aria-expanded for assistive tech, a
# cookie for the next page — and the bug this guards against is any one of them drifting.
#
# ── NOT PROVEN HERE ──────────────────────────────────────────────────────────────────
# The collapsed rail's hint bubble is CSS-only: `fixed` + anchor positioning is what
# lets it escape the nav's overflow-y-auto clip, and this harness serves no compiled
# stylesheet, so the bubble computes to `static` and never moves. Asserting its geometry
# here would prove nothing. It is proven in modelrails_base against real CSS:
# spec/system/ui/sidebar_behaviours_spec.rb. See docs/testing.md.
%w[default collapsed unremembered].each do |name|
  BrowserHarness.scenario("sidebar/#{name}", controllers: %w[sidebar]) do
    view = ActionController::Base.new.view_context
    UI::SidebarComponent.new(
      brand: "Acme", collapsed: name == "collapsed", remember: name != "unremembered"
    ).render_in(view) do |s|
      s.with_item(label: "Dashboard", href: "#", icon: :home, active: true)
      s.with_item(label: "Tasks", href: "#", icon: :tasks)
      nil
    end
  end
end

class SidebarSystemTest < BrowserTestCase
  COOKIE = "sidebar_collapsed"

  def toggle = find("aside button[aria-controls]")

  def cookie = page.driver.browser.cookies.all[COOKIE]&.value

  def test_reports_expanded_before_the_first_toggle
    visit_scenario("sidebar/default")

    assert_equal "true", toggle["aria-expanded"]
  end

  def test_toggling_moves_aria_expanded_with_the_css_state
    visit_scenario("sidebar/default")
    toggle.click

    assert_equal "false", toggle["aria-expanded"]
    assert_selector "aside[data-collapsed='true']"
    assert_no_stimulus_errors
  end

  # The two representations must not drift in either direction.
  def test_toggling_back_restores_both
    visit_scenario("sidebar/collapsed")

    assert_equal "false", toggle["aria-expanded"]

    toggle.click

    assert_equal "true", toggle["aria-expanded"]
    assert_selector "aside[data-collapsed='false']"
  end

  def test_the_choice_is_recorded_for_the_next_page
    visit_scenario("sidebar/default")
    toggle.click

    assert_equal "true", cookie

    toggle.click

    assert_equal "false", cookie
  end

  def test_remember_false_leaves_no_cookie
    visit_scenario("sidebar/unremembered")
    toggle.click

    assert_selector "aside[data-collapsed='true']"
    assert_nil cookie
  end
end
