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

  # Placement moved from `absolute` + offset classes to CSS anchor positioning, so the
  # panel is viewport-positioned and can be promoted to the top layer. The old
  # `.bottom-full.right-0` pair is now only the pre-Baseline fallback.
  def test_panel_carries_aaa_tokens
    render_popover(side: :top, align: :end)

    assert_selector "[data-floating-target='panel'].bg-surface-overlay.text-text-body", visible: :all
  end

  def test_panel_places_by_anchor_positioning_with_a_fallback
    render_popover(side: :top, align: :end)
    classes = page.find("[data-floating-target='panel']", visible: :all)[:class]

    assert_includes classes, "supports-[position-area:bottom]:[position-area:top_span-left]"
    assert_includes classes, "not-supports-[position-area:bottom]:bottom-full"
  end

  # The panel is tethered by name, so the anchor and the panel must agree.
  def test_panel_is_tethered_to_its_wrapper_anchor
    render_popover(side: :bottom, align: :start)

    anchor = page.find("[data-controller='floating']", visible: :all)[:style]
    panel = page.find("[data-floating-target='panel']", visible: :all)[:style]
    name = anchor[/anchor-name:\s*(--[\w-]+)/, 1]

    refute_nil name, "wrapper carries no anchor-name"
    assert_includes panel, "position-anchor: #{name}"
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

  # `trigger_class:` used to REPLACE the trigger's classes, so a caller styling the
  # trigger silently deleted its focus indicator and target-size floor — on the element
  # whose own docstring promises "a real <button> trigger". Every other class input in
  # these components merges via cn(); the trigger was the exception, on the one element
  # carrying an ARIA contract.
  def test_trigger_keeps_its_accessibility_floor_when_restyled
    render_inline(UI::PopoverComponent.new(label: "Account menu", trigger_class: "text-sm text-text-muted")) { |c| c.with_trigger { "Open" } }

    assert_selector "button[data-floating-target='trigger'].focus-ring", visible: :all
  end

  def test_trigger_still_applies_the_callers_classes
    render_inline(UI::PopoverComponent.new(label: "Account menu", trigger_class: "text-sm text-text-muted")) { |c| c.with_trigger { "Open" } }

    assert_selector "button.text-sm.text-text-muted", visible: :all
  end

  def test_default_trigger_is_unchanged
    render_inline(UI::PopoverComponent.new(label: "Account menu")) { |c| c.with_trigger { "Open" } }

    assert_selector "button.btn-secondary", visible: :all
  end
end
