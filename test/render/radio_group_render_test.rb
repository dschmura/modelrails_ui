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

  # A Rails field name is the ordinary case for this component, and it is full of
  # brackets. They are legal in an HTML5 id and `label[for]` resolves them, so the
  # page works — but `#workspace[join_policy]_invite` does not parse as a CSS id
  # selector (it reads as `#workspace` plus an attribute condition), so every
  # stylesheet rule, querySelector and test has to know to escape it.
  #
  # chip_group already collapses the brackets out of its ids. This keeps the two
  # siblings answering the same question the same way. (#247)
  def test_a_rails_field_name_yields_a_selector_safe_id
    render_inline(UI::RadioGroupComponent.new(
      name: "workspace[join_policy]",
      label: "Join policy",
      items: [{value: "invite", label: "Invitation only", description: "Admins invite each member."}]
    ))

    assert_selector "input[type='radio'][id='workspace_join_policy_invite']", visible: :all
    assert_selector "label[for='workspace_join_policy_invite']", text: "Invitation only"
  end

  # The description id is derived from the input's, so it inherits the fix rather
  # than needing its own — which is the reason to sanitise at the source.
  def test_a_sanitised_id_carries_into_the_description_wiring
    render_inline(UI::RadioGroupComponent.new(
      name: "workspace[join_policy]",
      label: "Join policy",
      items: [{value: "invite", label: "Invitation only", description: "Admins invite each member."}]
    ))

    assert_selector "input[aria-describedby='workspace_join_policy_invite_description']", visible: :all
    assert_selector "p#workspace_join_policy_invite_description"
  end

  # The posted NAME is untouched — only the id is sanitised. Rails needs the
  # brackets to parse the params, so collapsing them there would break the form.
  def test_sanitising_the_id_leaves_the_posted_name_alone
    render_inline(UI::RadioGroupComponent.new(
      name: "workspace[join_policy]", label: "Join policy",
      items: [{value: "invite", label: "Invitation only"}]
    ))

    assert_selector "input[name='workspace[join_policy]']", visible: :all
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

  # Uniform focus-ring utility (converged convention).
  def test_inputs_use_the_focus_ring_utility
    render_inline(UI::RadioGroupComponent.new(name: "plan", label: "Billing plan", items: PLAN_ITEMS))

    assert_selector "input.focus-ring"
  end

  # --- per-item descriptions (#137) ------------------------------------------
  #
  # A choice often needs a line of explanation per option. Without it, callers
  # hand-roll the radios and lose the group's whole accessibility contract.

  DESCRIBED_ITEMS = [
    {value: "open", label: "Open", description: "Anyone with the link can join."},
    {value: "invite", label: "Invite only", description: "An admin must invite each member."}
  ].freeze

  def render_described
    render_inline(UI::RadioGroupComponent.new(name: "policy", label: "Join policy", items: DESCRIBED_ITEMS))
  end

  def test_a_description_is_linked_to_its_own_input
    render_described

    assert_selector "input#policy_open[aria-describedby='policy_open_description']"
    assert_selector "#policy_open_description", text: "Anyone with the link can join."
  end

  # Each item points at its OWN description, never a shared or reused id.
  def test_each_item_gets_a_distinct_description_id
    render_described

    assert_selector "input#policy_invite[aria-describedby='policy_invite_description']"
    assert_selector "#policy_invite_description", text: "An admin must invite each member."
  end

  # The description must be a SIBLING of the label, not inside it: inside, it
  # becomes part of the radio's accessible name and is read as the option itself.
  def test_the_description_is_not_part_of_the_accessible_name
    render_described

    assert_no_selector "label #policy_open_description"
    assert_selector "label[for='policy_open']", text: "Open", exact_text: true
  end

  # An item with no description is untouched — no dangling aria-describedby.
  def test_an_item_without_a_description_gets_no_aria_describedby
    render_inline(UI::RadioGroupComponent.new(name: "plan", label: "Billing plan", items: PLAN_ITEMS))

    assert_no_selector "input[aria-describedby]"
  end

  # The label stays the click target and keeps its 44px floor even when stacked
  # above a description.
  def test_a_described_items_label_keeps_the_44px_target_floor
    render_described

    assert_selector "label[for='policy_open'].min-h-11"
  end
end
