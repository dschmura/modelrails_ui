# frozen_string_literal: true

require "system_test_helper"
require "securerandom"
load_component "combobox", "combobox_component.rb.tt"

OPTIONS = [
  {value: "us", label: "United States"},
  {value: "ca", label: "Canada"},
  {value: "mx", label: "Mexico"}
].freeze

BrowserHarness.scenario("combobox/basic", controllers: %w[combobox], modules: %w[overlays/top_layer]) do
  view = ActionController::Base.new.view_context
  UI::ComboboxComponent.new(name: "country", label: "Country", options: OPTIONS).render_in(view)
end

BrowserHarness.scenario("combobox/two", controllers: %w[combobox], modules: %w[overlays/top_layer]) do
  view = ActionController::Base.new.view_context
  UI::ComboboxComponent.new(name: "origin", label: "Origin", options: OPTIONS).render_in(view) +
    UI::ComboboxComponent.new(name: "destination", label: "Destination", options: OPTIONS).render_in(view)
end

# Filtering, activedescendant and commit are all runtime behaviour. The duplicate-id case
# especially: ids minted by the controller at runtime cannot be checked from markup at all.
class ComboboxSystemTest < BrowserTestCase
  def input = find("[data-combobox-target=input]")

  def test_focusing_the_input_opens_the_listbox
    visit_scenario("combobox/basic")
    input.click

    assert_selector "[role=listbox]"
    assert_selector "[role=option]", count: 3
  end

  def test_typing_filters_the_options
    visit_scenario("combobox/basic")
    input.click
    input.send_keys("can")

    assert_selector "[role=option]", count: 1, text: "Canada"
  end

  def test_no_match_shows_the_empty_state
    visit_scenario("combobox/basic")
    input.click
    input.send_keys("zzzz")

    assert_no_selector "[role=option]"
    assert_selector "[data-combobox-target=empty]"
  end

  # aria-activedescendant must name a real element — a stale or absent id silently breaks
  # the announcement while looking fine in the DOM.
  def test_arrow_down_points_activedescendant_at_a_real_option
    visit_scenario("combobox/basic")
    input.click
    press(:Down)

    resolved = page.evaluate_script(<<~JS)
      (() => {
        const input = document.querySelector("[data-combobox-target=input]");
        const id = input.getAttribute("aria-activedescendant");
        const el = id && document.getElementById(id);
        return JSON.stringify({ id: id, exists: !!el, isOption: el ? el.getAttribute("role") === "option" : false });
      })()
    JS
    state = JSON.parse(resolved)

    assert state["exists"], "aria-activedescendant=#{state["id"].inspect} names no element"
    assert state["isOption"], "aria-activedescendant does not name an option"
  end

  def test_choosing_an_option_commits_the_value
    visit_scenario("combobox/basic")
    input.click
    find("[role=option]", text: "Mexico").click

    assert_equal "mx", page.evaluate_script(%{document.querySelector("[data-combobox-target=hidden]").value})
    assert_no_stimulus_errors
  end

  # The runtime half of the duplicate-id fix: option ids are minted by the controller, so
  # two instances with a shared prefix collide and aria-activedescendant becomes ambiguous.
  def test_option_ids_are_unique_across_two_instances
    visit_scenario("combobox/two")
    page.all("[data-combobox-target=input]").each(&:click)
    ids = page.evaluate_script(%{[...document.querySelectorAll("[role=option]")].map(o => o.id)})

    assert_operator ids.length, :>=, 6
    assert_equal ids.uniq.length, ids.length, "duplicate option ids across instances: #{ids.inspect}"
  end

  def test_open_combobox_passes_a_structural_axe_audit
    visit_scenario("combobox/basic")
    input.click

    assert_axe_clean
  end
end
