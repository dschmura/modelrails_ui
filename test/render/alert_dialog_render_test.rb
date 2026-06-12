# frozen_string_literal: true

require "render_test_helper"
require "securerandom"
load_component "alert_dialog", "alert_dialog_component.rb.tt"

# STRUCTURE-only render specs. The modal Stimulus controller's BEHAVIOR (showModal
# on trigger, Escape/backdrop close, focus trap + restore) is verified by the
# preview-host browser spec (spec/system/ui/alert_dialog_component_spec.rb in the
# app) — the render harness CANNOT exercise JS, so here we assert the static
# <dialog> scaffolding the controller relies on (a closed native dialog with full ARIA).
class AlertDialogRenderTest < ViewComponent::TestCase
  def test_renders_a_native_alertdialog_with_modal_semantics
    render_inline(UI::AlertDialogComponent.new(title: "Delete account?"))

    assert_selector "dialog[role='alertdialog'][aria-modal='true']", visible: :all
  end

  def test_title_is_the_accessible_name_via_aria_labelledby
    render_inline(UI::AlertDialogComponent.new(title: "Delete account?", id: "a1"))

    assert_selector "dialog[aria-labelledby='a1-title']", visible: :all
    assert_selector "h2#a1-title", text: "Delete account?", visible: :all
  end

  def test_description_wires_aria_describedby
    render_inline(UI::AlertDialogComponent.new(title: "T", id: "a2", description: "This action cannot be undone."))

    assert_selector "dialog[aria-describedby='a2-description']", visible: :all
    assert_selector "p#a2-description", text: "This action cannot be undone.", visible: :all
  end

  def test_omits_aria_describedby_without_a_description
    render_inline(UI::AlertDialogComponent.new(title: "T", id: "a3"))

    assert_no_selector "dialog[aria-describedby]", visible: :all
  end

  def test_renders_an_accessible_close_button_wired_to_the_controller
    render_inline(UI::AlertDialogComponent.new(title: "T"))

    assert_selector "button[type='button'][aria-label='Close'][data-action~='click->modal#close']", visible: :all
  end

  # AAA semantic tokens (the design-token guarantee), not raw Tailwind:
  def test_renders_with_aaa_tokens
    render_inline(UI::AlertDialogComponent.new(title: "T"))

    assert_selector "[data-modal-target='panel'].bg-surface-overlay", visible: :all
    assert_selector "h2.text-text-heading", visible: :all
  end

  def test_wrapper_false_renders_only_the_dialog
    render_inline(UI::AlertDialogComponent.new(title: "T", wrapper: false))

    assert_no_selector "[data-controller='modal']", visible: :all
    assert_selector "dialog[role='alertdialog']", visible: :all
  end

  def test_footer_slot_renders_in_a_footer_area
    render_inline(UI::AlertDialogComponent.new(title: "T")) do |alert_dialog|
      alert_dialog.with_footer { "Confirm" }
    end

    assert_text "Confirm"
  end
end
