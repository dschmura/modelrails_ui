# frozen_string_literal: true

require "render_test_helper"
require "securerandom"
load_component "dialog", "dialog_component.rb.tt"

# STRUCTURE-only render specs. The modal Stimulus controller's BEHAVIOR (showModal
# on trigger, Escape/backdrop close, focus trap + restore) is verified by the
# preview-host browser spec (spec/system/ui/dialog_component_spec.rb in the app) —
# the render harness CANNOT exercise JS, so here we assert the static <dialog>
# scaffolding the controller relies on (a closed native dialog with full ARIA).
class DialogRenderTest < ViewComponent::TestCase
  def test_renders_a_native_dialog_with_modal_semantics
    render_inline(UI::DialogComponent.new(title: "Edit profile"))

    assert_selector "dialog[role='dialog'][aria-modal='true']", visible: :all
  end

  def test_title_is_the_accessible_name_via_aria_labelledby
    render_inline(UI::DialogComponent.new(title: "Edit profile", id: "m1"))

    assert_selector "dialog[aria-labelledby='m1-title']", visible: :all
    assert_selector "h2#m1-title", text: "Edit profile", visible: :all
  end

  def test_description_wires_aria_describedby
    render_inline(UI::DialogComponent.new(title: "T", id: "m2", description: "Sub text"))

    assert_selector "dialog[aria-describedby='m2-description']", visible: :all
    assert_selector "p#m2-description", text: "Sub text", visible: :all
  end

  def test_omits_aria_describedby_without_a_description
    render_inline(UI::DialogComponent.new(title: "T", id: "m3"))

    assert_no_selector "dialog[aria-describedby]", visible: :all
  end

  def test_renders_an_accessible_close_button_wired_to_the_controller
    render_inline(UI::DialogComponent.new(title: "T"))

    assert_selector "button[type='button'][aria-label='Close'][data-action~='click->modal#close']", visible: :all
  end

  # AAA semantic tokens (the design-token guarantee), not raw Tailwind:
  def test_renders_with_aaa_tokens
    render_inline(UI::DialogComponent.new(title: "T"))

    assert_selector "[data-modal-target='panel'].bg-surface-overlay", visible: :all
    assert_selector "h2.text-text-heading", visible: :all
  end

  def test_wrapper_renders_the_modal_controller_and_trigger_action
    render_inline(UI::DialogComponent.new(title: "T")) do |dialog|
      dialog.with_trigger { "Open" }
    end

    assert_selector "div[data-controller='modal']", visible: :all
    assert_selector "span[data-action~='click->modal#open']", text: "Open", visible: :all
  end

  def test_wrapper_false_renders_only_the_dialog
    render_inline(UI::DialogComponent.new(title: "T", wrapper: false))

    assert_no_selector "[data-controller='modal']", visible: :all
    assert_selector "dialog[role='dialog']", visible: :all
  end

  def test_size_maps_to_a_max_width_on_the_panel
    render_inline(UI::DialogComponent.new(title: "T", size: :lg))

    assert_selector "[data-modal-target='panel'].max-w-2xl", visible: :all
  end

  def test_footer_slot_renders_in_a_footer_area
    render_inline(UI::DialogComponent.new(title: "T")) do |dialog|
      dialog.with_footer { "Footer actions" }
    end

    assert_text "Footer actions"
  end
end
