# frozen_string_literal: true

require "system_test_helper"
load_component "checkbox", "checkbox_component.rb.tt"

BrowserHarness.scenario("checkbox/indeterminate", controllers: %w[indeterminate]) do
  view = ActionController::Base.new.view_context
  UI::CheckboxComponent.new(label: "Select all", indeterminate: true, name: "all").render_in(view) +
    UI::CheckboxComponent.new(label: "Invoices", name: "invoices").render_in(view)
end

# `indeterminate` is a DOM property with no HTML attribute, so the render lane can only
# see that a controller was WIRED. Whether the property is actually set — and cleared once
# the user acts — exists solely at runtime.
class CheckboxSystemTest < BrowserTestCase
  def setup
    super
    visit_scenario("checkbox/indeterminate")
  end

  def indeterminate?(name)
    page.evaluate_script(%{document.querySelector("input[name='#{name}']").indeterminate})
  end

  def test_the_property_the_markup_could_not_carry_is_set
    assert indeterminate?("all")
  end

  # The control: without it, reading a default `false` would look like a pass.
  def test_a_plain_checkbox_is_left_alone
    refute indeterminate?("invoices")
  end

  def test_acting_on_it_clears_the_partial_state
    find("input[name='all']").click

    refute indeterminate?("all")
    assert_no_stimulus_errors
  end

  # A tri-state parent means "some children selected" — it must not submit as checked.
  def test_the_partial_parent_is_not_checked
    refute page.evaluate_script(%{document.querySelector("input[name='all']").checked})
  end
end
