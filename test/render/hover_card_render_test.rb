# frozen_string_literal: true

require "render_test_helper"
require "securerandom"
load_component "hover_card", "hover_card_component.rb.tt"

class HoverCardRenderTest < ViewComponent::TestCase
  def render_card(**opts)
    render_inline(UI::HoverCardComponent.new(**opts)) do |c|
      c.with_trigger { "@dave" }
      "Profile details"
    end
  end

  def test_wrapper_wires_floating_and_dismissal
    render_card

    assert_selector "span.group[data-controller='floating']" \
                    "[data-action~='keydown.esc->floating#dismiss']" \
                    "[data-action~='mouseleave->floating#clearDismissed']", visible: :all
  end

  def test_wrapper_wires_focusout
    render_card

    assert_selector "span[data-action~='focusout->floating#clearDismissed']", visible: :all
  end

  def test_card_shows_on_hover_and_focus_within
    render_card

    assert_selector "div.group-hover\\:visible.group-focus-within\\:visible", visible: :all
  end

  def test_card_force_hides_when_dismissed
    render_card

    assert_selector "div.group-data-\\[dismissed\\]\\:invisible\\!", visible: :all
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
