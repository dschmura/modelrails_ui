# frozen_string_literal: true

require "system_test_helper"
require "securerandom"
load_component "popover", "popover_component.rb.tt"

BrowserHarness.scenario("popover/basic", controllers: %w[floating], modules: %w[overlays/top_layer]) do
  view = ActionController::Base.new.view_context
  popover = UI::PopoverComponent.new(label: "Account menu").render_in(view) do |c|
    c.with_trigger { "Open popover" }
    view.tag.a("Sign out", href: "#")
  end
  # An unambiguous outside target: clicking a wrapper that CONTAINS the popover would land
  # inside it and prove nothing about outside-click dismissal.
  popover + view.tag.button("elsewhere", type: "button", id: "outside")
end

# Open/close, aria-expanded sync and focus return — none of it visible to the render lane.
#
# NOT covered here: top-layer promotion — unprovable without compiled CSS. See
# docs/testing.md; `assert_promoted_to_top_layer` fails with the reason if you try.
class PopoverSystemTest < BrowserTestCase
  def setup
    super
    visit_scenario("popover/basic")
  end

  def test_panel_is_hidden_until_the_trigger_is_used
    assert_no_selector "[data-floating-target=panel]"
    assert_selector "[data-floating-target=trigger][aria-expanded='false']"
  end

  def test_clicking_the_trigger_opens_and_syncs_aria_expanded
    find("[data-floating-target=trigger]").click

    assert_selector "[data-floating-target=panel]"
    assert_selector "[data-floating-target=trigger][aria-expanded='true']"
  end

  def test_escape_closes_and_returns_focus_to_the_trigger
    find("[data-floating-target=trigger]").click

    assert_selector "[data-floating-target=panel]"

    press(:Escape)

    assert_no_selector "[data-floating-target=panel]"
    assert_equal "Open popover", page.evaluate_script("document.activeElement.textContent.trim()")
  end

  def test_a_click_outside_closes_it
    find("[data-floating-target=trigger]").click

    assert_selector "[data-floating-target=panel]"

    find("#outside").click

    assert_no_selector "[data-floating-target=panel]"
  end

  def test_toggling_twice_returns_to_the_closed_state
    trigger = find("[data-floating-target=trigger]")
    trigger.click
    trigger.click

    assert_no_selector "[data-floating-target=panel]"
    assert_no_stimulus_errors
  end

  def test_open_popover_passes_a_structural_axe_audit
    find("[data-floating-target=trigger]").click

    assert_axe_clean
  end
end
