# frozen_string_literal: true

require "render_test_helper"
load_component "radio_group", "radio_group_component.rb.tt"

class RadioGroupRenderTest < ViewComponent::TestCase
  PLAN_ITEMS = [
    {value: "free", label: "Free"},
    {value: "pro", label: "Pro"},
    {value: "team plan", label: "Team plan"}
  ].freeze

  def test_renders_a_named_radiogroup
    render_inline(UI::RadioGroupComponent.new(name: "plan", label: "Billing plan", items: PLAN_ITEMS))

    # A role=radiogroup MUST carry an accessible name (empty group name is an a11y failure).
    assert_selector "div[role='radiogroup'][aria-label='Billing plan']"
  end

  def test_each_item_is_a_radio_input_with_a_matching_label
    render_inline(UI::RadioGroupComponent.new(name: "plan", label: "Billing plan", items: PLAN_ITEMS))

    PLAN_ITEMS.each do |item|
      id = "plan_#{item[:value].gsub(/\W/, "_")}"

      assert_selector "input[type='radio'][name='plan'][value='#{item[:value]}'][id='#{id}']"
      assert_selector "label[for='#{id}']", text: item[:label]
    end
  end

  def test_a_checked_item_marks_only_that_input
    items = [
      {value: "free", label: "Free"},
      {value: "pro", label: "Pro", checked: true}
    ]
    render_inline(UI::RadioGroupComponent.new(name: "plan", label: "Billing plan", items: items))

    assert_selector "input[type='radio'][id='plan_pro'][checked]"
    assert_no_selector "input[type='radio'][id='plan_free'][checked]"
  end

  def test_a_disabled_item_is_honored
    items = [
      {value: "free", label: "Free"},
      {value: "enterprise", label: "Enterprise", disabled: true}
    ]
    render_inline(UI::RadioGroupComponent.new(name: "plan", label: "Billing plan", items: items))

    assert_selector "input[type='radio'][id='plan_enterprise'][disabled]"
    assert_no_selector "input[type='radio'][id='plan_free'][disabled]"
  end

  def test_invalid_sets_aria_invalid_on_the_group
    render_inline(UI::RadioGroupComponent.new(name: "plan", label: "Billing plan", items: PLAN_ITEMS, invalid: true))

    assert_selector "div[role='radiogroup'][aria-invalid='true']"
  end

  def test_absent_invalid_does_not_set_aria_invalid
    render_inline(UI::RadioGroupComponent.new(name: "plan", label: "Billing plan", items: PLAN_ITEMS))

    assert_no_selector "div[role='radiogroup'][aria-invalid]"
  end

  def test_describedby_links_the_group_to_a_hint_or_error
    render_inline(
      UI::RadioGroupComponent.new(
        name: "plan", label: "Billing plan", items: PLAN_ITEMS, describedby: "plan-error"
      )
    )

    assert_selector "div[role='radiogroup'][aria-describedby='plan-error']"
  end

  def test_absent_describedby_does_not_set_aria_describedby
    render_inline(UI::RadioGroupComponent.new(name: "plan", label: "Billing plan", items: PLAN_ITEMS))

    assert_no_selector "div[role='radiogroup'][aria-describedby]"
  end

  def test_caller_html_attrs_cannot_clobber_the_groups_a11y_contract
    render_inline(
      UI::RadioGroupComponent.new(
        name: "plan", label: "Billing plan", items: PLAN_ITEMS, invalid: true,
        role: "group", "aria-label": "Caller override", "aria-invalid": "false"
      )
    )

    # Component wins: its role/aria-label/aria-invalid survive caller-supplied conflicts.
    assert_selector "div[role='radiogroup'][aria-label='Billing plan'][aria-invalid='true']"
    assert_no_selector "div[role='group']"
    assert_no_selector "div[aria-label='Caller override']"
  end

  # AAA semantic tokens (the design-token guarantee), not raw Tailwind:
  def test_inputs_use_semantic_aaa_tokens
    render_inline(UI::RadioGroupComponent.new(name: "plan", label: "Billing plan", items: PLAN_ITEMS))

    assert_selector "input.border-interactive"
    assert_selector "input.accent-interactive"
  end

  # Standard library 3px focus ring (not ring-1), matching the other form controls.
  def test_inputs_use_the_standard_3px_focus_ring
    render_inline(UI::RadioGroupComponent.new(name: "plan", label: "Billing plan", items: PLAN_ITEMS))

    assert_selector "input.focus-visible\\:ring-\\[3px\\]"
    assert_selector "input.focus-visible\\:ring-interactive-focus"
  end
end
