# frozen_string_literal: true

require "render_test_helper"
require "securerandom"
load_component "popover", "popover_component.rb.tt"

# STRUCTURE-only render specs. The `floating` controller's BEHAVIOR (click toggle,
# Escape/outside close, focus return) is proven by the app 0b browser spec
# (spec/system/ui/popover_component_spec.rb) — the render harness cannot exercise
# JS, so here we assert the static scaffolding the controller relies on.
class PopoverRenderTest < ViewComponent::TestCase
  def render_popover(**opts)
    attrs = {label: "Account menu"}.merge(opts)
    render_inline(UI::PopoverComponent.new(**attrs)) do |c|
      c.with_trigger { "Open" }
      "Panel body"
    end
  end

  def test_wrapper_wires_the_floating_controller_and_dismissal_actions
    render_popover

    assert_selector "div[data-controller='floating']" \
                    "[data-action~='keydown.esc->floating#close']" \
                    "[data-action~='click@document->floating#closeOnClickOutside']", visible: :all
  end

  def test_trigger_is_a_real_button_with_popup_aria
    render_popover(id: "p1")

    assert_selector "button[type='button'][aria-haspopup='dialog'][aria-expanded='false']" \
                    "[aria-controls='p1'][data-floating-target='trigger']" \
                    "[data-action~='click->floating#toggle']", text: "Open", visible: :all
  end

  def test_panel_is_a_labelled_dialog_hidden_until_open
    render_popover(id: "p2", label: "Account menu")

    assert_selector "div#p2[role='dialog'][aria-label='Account menu'][tabindex='-1'][hidden]" \
                    "[data-floating-target='panel']", visible: :all
  end

  def test_panel_carries_aaa_tokens_and_positioning
    render_popover(side: :top, align: :end)

    assert_selector "[data-floating-target='panel'].bg-surface-overlay.text-text-body", visible: :all
    assert_selector "[data-floating-target='panel'].bottom-full.right-0", visible: :all
  end

  def test_requires_a_trigger_slot
    error = assert_raises(ArgumentError) do
      render_inline(UI::PopoverComponent.new(label: "Account menu"))
    end
    assert_match(/with_trigger/, error.message)
  end

  def test_fail_loud_on_unknown_side
    error = assert_raises(ArgumentError) do
      UI::PopoverComponent.new(label: "x", side: :sideways)
    end
    assert_match(/unknown side/, error.message)
  end

  def test_fail_loud_on_unknown_align
    assert_raises(ArgumentError) do
      UI::PopoverComponent.new(label: "x", align: :middle)
    end
  end
end
