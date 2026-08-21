# frozen_string_literal: true

require "system_test_helper"
require "securerandom"
load_component "tabs", "tabs_item_component.rb.tt"
load_component "tabs", "tabs_component.rb.tt"

ORIENTATIONS = %w[horizontal vertical].freeze
ACTIVATIONS = %w[automatic manual].freeze

ORIENTATIONS.each do |orientation|
  ACTIVATIONS.each do |activation|
    BrowserHarness.scenario("tabs/#{orientation}_#{activation}", controllers: %w[tabs]) do
      view = ActionController::Base.new.view_context
      UI::TabsComponent.new(label: "Sections", orientation: orientation.to_sym, activation: activation.to_sym)
        .render_in(view) do |t|
          t.with_tab(title: "One") { "first panel" }
          t.with_tab(title: "Two") { "second panel" }
          t.with_tab(title: "Three") { "third panel" }
          nil
        end
    end
  end
end

# The keyboard model is the whole component, and none of it is visible to the render lane:
# which arrow keys navigate, whether focus alone reveals a panel, and the roving tabindex
# that keeps exactly one tab in the tab order.
class TabsSystemTest < BrowserTestCase
  def selected_tab = find("[role=tab][aria-selected=true]").text
  def focused = page.evaluate_script("document.activeElement.textContent.trim()")

  def open_scenario(name)
    visit_scenario("tabs/#{name}")
    find("[role=tab]", text: "One").click
  end

  def test_horizontal_arrow_right_moves_and_activates
    open_scenario("horizontal_automatic")
    press(:Right)

    assert_equal "Two", selected_tab
  end

  # The control that keeps the vertical case honest: the unused axis must stay inert so
  # those keys are left to the page.
  def test_horizontal_ignores_arrow_down
    open_scenario("horizontal_automatic")
    press(:Down)

    assert_equal "One", selected_tab
  end

  def test_vertical_arrow_down_moves_and_activates
    open_scenario("vertical_automatic")
    press(:Down)

    assert_equal "Two", selected_tab
  end

  def test_vertical_ignores_arrow_right
    open_scenario("vertical_automatic")
    press(:Right)

    assert_equal "One", selected_tab
  end

  def test_manual_moves_focus_without_revealing_the_panel
    open_scenario("horizontal_manual")
    press(:Right)

    assert_equal "Two", focused
    assert_equal "One", selected_tab
  end

  def test_manual_reveals_on_enter
    open_scenario("horizontal_manual")
    press(:Right)
    press(:Enter)

    assert_equal "Two", selected_tab
  end

  # Roving tabindex: exactly one tab is reachable by Tab at any time, and in manual mode
  # the tab stop follows focus rather than selection.
  def test_exactly_one_tab_is_in_the_tab_order
    open_scenario("horizontal_automatic")
    press(:Right)
    zeroes = page.evaluate_script(%{[...document.querySelectorAll("[role=tab]")].filter(t => t.tabIndex === 0).length})

    assert_equal 1, zeroes
  end

  def test_manual_tab_stop_follows_focus_not_selection
    open_scenario("horizontal_manual")
    press(:Right)
    stop = page.evaluate_script(%{document.querySelector("[role=tab][tabindex='0']").textContent.trim()})

    assert_equal "Two", stop
    assert_equal "One", selected_tab
  end

  def test_only_the_active_panel_is_visible
    open_scenario("horizontal_automatic")
    press(:Right)

    assert_selector "[role=tabpanel]:not([hidden])", count: 1
    assert_no_stimulus_errors
  end

  def test_tablist_passes_a_structural_axe_audit
    open_scenario("vertical_manual")

    assert_axe_clean
  end
end
