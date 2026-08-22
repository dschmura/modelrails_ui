# frozen_string_literal: true

require "system_test_helper"
require "securerandom"
load_component "dialog", "modal_chrome.rb.tt"
load_component "drawer", "drawer_component.rb.tt"

BrowserHarness.scenario("drawer/basic", controllers: %w[modal drawer-drag]) do
  view = ActionController::Base.new.view_context
  UI::DrawerComponent.new(title: "More options", id: "drawer-basic", description: "Pick one.").render_in(view) do |c|
    c.with_trigger { "Open drawer" }
    view.tag.p("Body content.")
  end
end

# Drag-to-dismiss only exists at runtime, and only in response to real pointer input —
# the render lane sees a handle and cannot tell whether it does anything.
#
# NOTE: this harness serves no compiled CSS, so the drawer is UA-styled rather than
# bottom-anchored. That is fine for the gesture logic under test (thresholds derive from
# the panel's own measured height), but anything depending on the drawer's real position
# belongs in modelrails_base. See docs/testing.md.
class DrawerSystemTest < BrowserTestCase
  def setup
    super
    visit_scenario("drawer/basic")
    find("[data-action='click->modal#open']").click
    find("dialog[open]") # blocks until it opens; not an assertion in a lifecycle hook
    settle
  end

  # The drawer animates in; measuring the handle mid-animation gives a position the
  # pointer never lands on, so the press hits whatever has slid into that spot.
  def settle
    Timeout.timeout(5) do
      loop do
        first = handle_box["y"]
        sleep 0.05
        break if (handle_box["y"] - first).abs < 0.5
      end
    end
  end

  def handle_box
    JSON.parse(page.evaluate_script(
      %{JSON.stringify(document.querySelector("[data-action*='drawer-drag#start']").getBoundingClientRect().toJSON())}
    ))
  end

  def drag(by:)
    box = handle_box
    x = (box["x"] + box["width"] / 2).round
    y = (box["y"] + box["height"] / 2).round
    mouse = page.driver.browser.mouse
    mouse.move(x: x, y: y).down
    mouse.move(x: x, y: y + by, steps: 8) if by.positive?
    mouse.up
  end

  def test_dragging_past_the_threshold_dismisses
    drag(by: 200)

    assert_no_selector "dialog[open]"
  end

  def test_a_small_drag_springs_back
    drag(by: 6)

    assert_selector "dialog[open]"
  end

  # The control: without it, "dragging dismisses" could be passing because any pointer
  # interaction closes the drawer.
  def test_press_and_release_without_moving_keeps_it_open
    drag(by: 0)

    assert_selector "dialog[open]"
    assert_no_stimulus_errors
  end

  # Drag is an addition, never the only way out — it is pointer-only by nature.
  def test_escape_still_closes_it
    press(:Escape)

    assert_no_selector "dialog[open]"
  end
end
