# frozen_string_literal: true

require "render_test_helper"
require "securerandom"
load_component "drawer", "drawer_component.rb.tt"

# STRUCTURE-only render specs. The modal Stimulus controller's BEHAVIOR (showModal
# on trigger, Escape/backdrop close, focus trap + restore) is verified by the
# preview-host browser spec (spec/system/ui/drawer_component_spec.rb in the
# app) — the render harness CANNOT exercise JS, so here we assert the static
# <dialog> scaffolding the controller relies on (a closed native dialog with full ARIA).
class DrawerRenderTest < ViewComponent::TestCase
  def test_renders_a_native_dialog_with_modal_semantics
    render_inline(UI::DrawerComponent.new(title: "Share item"))

    assert_selector "dialog[role='dialog'][aria-modal='true']", visible: :all
  end

  def test_title_is_the_accessible_name_via_aria_labelledby
    render_inline(UI::DrawerComponent.new(title: "Share item", id: "d1"))

    assert_selector "dialog[aria-labelledby='d1-title']", visible: :all
    assert_selector "h2#d1-title", text: "Share item", visible: :all
  end

  def test_description_wires_aria_describedby
    render_inline(UI::DrawerComponent.new(title: "T", id: "d2", description: "Select a destination."))

    assert_selector "dialog[aria-describedby='d2-description']", visible: :all
    assert_selector "p#d2-description", text: "Select a destination.", visible: :all
  end

  def test_omits_aria_describedby_without_a_description
    render_inline(UI::DrawerComponent.new(title: "T", id: "d3"))

    assert_no_selector "dialog[aria-describedby]", visible: :all
  end

  def test_renders_an_accessible_close_button_wired_to_the_controller
    render_inline(UI::DrawerComponent.new(title: "T"))

    assert_selector "button[type='button'][aria-label='Close'][data-action~='click->modal#close']", visible: :all
  end

  def test_drag_handle_is_decorative
    render_inline(UI::DrawerComponent.new(title: "T"))

    assert_selector "[aria-hidden='true'] .bg-surface-sunken", visible: :all
  end

  # AAA semantic tokens (the design-token guarantee), not raw Tailwind:
  def test_renders_with_aaa_tokens
    render_inline(UI::DrawerComponent.new(title: "T"))

    assert_selector "[data-modal-target='panel'].bg-surface-overlay", visible: :all
    assert_selector "h2.text-text-heading", visible: :all
  end

  def test_wrapper_passes_slide_transform_values
    render_inline(UI::DrawerComponent.new(title: "T"))

    assert_selector "[data-controller='modal'][data-modal-enter-transform-value='translateY(0)']", visible: :all
    assert_selector "[data-modal-leave-transform-value='translateY(100%)']", visible: :all
  end

  def test_wrapper_false_renders_only_the_dialog
    render_inline(UI::DrawerComponent.new(title: "T", wrapper: false))

    assert_no_selector "[data-controller='modal']", visible: :all
    assert_selector "dialog[role='dialog']", visible: :all
  end

  def test_footer_slot_renders_in_a_footer_area
    render_inline(UI::DrawerComponent.new(title: "T")) do |drawer|
      drawer.with_footer { "Done" }
    end

    assert_text "Done"
  end
end
