# frozen_string_literal: true

require "system_test_helper"
require "securerandom"
load_component "dropdown_menu", "dropdown_menu_component.rb.tt"

# Rendering a slotted component needs a view context, so build the HTML the same way the
# render lane does rather than going through a controller.
BrowserHarness.scenario("dropdown_menu/submenu",
  controllers: %w[menu submenu], modules: %w[overlays/top_layer keyboard/keyboard_nav]) do
  view = ActionController::Base.new.view_context
  UI::DropdownMenuComponent.new.render_in(view) do |c|
    c.with_trigger { "Actions" }
    c.with_item { "Edit" }
    c.with_item(submenu: "Share") do |sub|
      sub.with_item { "Email" }
      sub.with_item { "Copy link" }
    end
    nil
  end
end

# The behaviour half of dropdown_menu — the part the render lane explicitly cannot reach.
# Every assertion here corresponds to something that shipped broken and was found only by
# driving a browser in the host app.
class DropdownMenuSystemTest < BrowserTestCase
  def setup
    super
    visit_scenario("dropdown_menu/submenu")
    open_menu
  end

  # Not an assertion in setup: Capybara's finder already blocks until the menu appears, so
  # this both opens the menu and waits for it.
  def open_menu
    find("[data-menu-target=trigger]").click
    find("[data-menu-target=menu]")
  end

  def test_menu_opens_and_syncs_aria_expanded
    assert_selector "[data-menu-target=trigger][aria-expanded='true']"
  end

  def test_arrow_keys_move_roving_focus
    press(:Down)

    assert_equal "Share", page.evaluate_script("document.activeElement.textContent.trim()")
  end

  # The panel carries tabindex="-1", so clicking its padding or a separator
  # focuses the PANEL — no item is active and indexOf(activeElement) is -1.
  # APG: ArrowUp from that state enters at the LAST item; the unguarded modulo
  # landed on items[n-2], silently skipping the last item. (Focus set via JS —
  # deterministic stand-in for a padding click, same activeElement state.)
  def test_arrow_up_with_focus_on_the_panel_enters_at_the_last_item
    page.execute_script("document.querySelector('[data-menu-target=menu]').focus()")
    press(:Up)

    assert_equal "Share", page.evaluate_script("document.activeElement.textContent.trim()")
  end

  def test_submenu_opens_on_arrow_right
    press(:Down)
    press(:Right)

    assert_selector "[data-submenu-target=panel]"
    assert_equal "Email", page.evaluate_script("document.activeElement.textContent.trim()")
  end

  # Regression: a submenu is its own controller and did not close when its parent did,
  # leaving aria-expanded="true" while the menu was shut and reappearing already expanded.
  def test_closing_the_parent_closes_the_submenu
    press(:Down)
    press(:Right)

    assert_selector "[data-submenu-target=panel]"

    find("[data-menu-target=trigger]").click

    assert_no_selector "[data-menu-target=menu]"
    assert_equal "false", find("[data-submenu-target=trigger]", visible: :all)["aria-expanded"]
  end

  def test_reopening_the_parent_leaves_the_submenu_collapsed
    press(:Down)
    press(:Right)
    find("[data-menu-target=trigger]").click
    find("[data-menu-target=trigger]").click

    assert_selector "[data-menu-target=menu]"
    assert_no_selector "[data-submenu-target=panel]"
  end

  # Checkable items toggle in place and keep the menu open (APG); plain items close it.
  def test_escape_closes_only_the_topmost_layer
    press(:Down)
    press(:Right)

    assert_selector "[data-submenu-target=panel]"

    press(:Escape)

    assert_no_selector "[data-submenu-target=panel]"
    assert_selector "[data-menu-target=menu]"
  end
end
