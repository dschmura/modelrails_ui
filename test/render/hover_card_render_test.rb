# frozen_string_literal: true

require "render_test_helper"
require "securerandom"
load_component "hover_card", "hover_card_component.rb.tt"

# STRUCTURE-only render specs. The hover-intent BEHAVIOR (open/close with delay across
# the trigger→card gap, Escape + focus return) is proven by the app 0b browser spec —
# the render harness cannot exercise JS, so here we assert the static scaffolding the
# `floating` controller drives.
class HoverCardRenderTest < ViewComponent::TestCase
  def render_card(**opts)
    render_inline(UI::HoverCardComponent.new(**opts)) do |c|
      c.with_trigger { "@dave" }
      "Profile details"
    end
  end

  def test_wrapper_wires_hover_intent_pointer_actions
    render_card

    assert_selector "span.group[data-controller='floating']" \
                    "[data-action~='mouseenter->floating#hoverOpen']" \
                    "[data-action~='mouseleave->floating#hoverClose']", visible: :all
  end

  def test_wrapper_wires_focus_and_escape_actions
    render_card

    assert_selector "span[data-action~='focusin->floating#hoverOpen']" \
                    "[data-action~='focusout->floating#hoverClose']" \
                    "[data-action~='keydown.esc->floating#hoverEscape']", visible: :all
  end

  def test_card_is_the_panel_target_shown_by_open_state
    render_card

    assert_selector "div[data-floating-target='panel']",
      class: ["invisible", "opacity-0", "group-data-[state=open]:visible", "group-data-[state=open]:opacity-100"],
      visible: :all
  end

  def test_label_sets_role_group_and_aria_label
    render_card(label: "User card")

    assert_selector "div[role='group'][aria-label='User card']", visible: :all
  end

  def test_omits_role_without_a_label
    render_card

    assert_no_selector "div[role='group']", visible: :all
  end

  def test_requires_a_trigger_slot
    error = assert_raises(ArgumentError) { render_inline(UI::HoverCardComponent.new) }
    assert_match(/with_trigger/, error.message)
  end

  def test_fail_loud_on_unknown_side
    assert_raises(ArgumentError) { UI::HoverCardComponent.new(side: :diagonal) }
  end
end
