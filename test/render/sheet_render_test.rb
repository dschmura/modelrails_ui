# frozen_string_literal: true

require "render_test_helper"
require "securerandom"
load_component "sheet", "sheet_component.rb.tt"

# STRUCTURE-only render specs. The modal Stimulus controller's BEHAVIOR (showModal
# on trigger, Escape/backdrop close, focus trap + restore) is verified by the
# preview-host browser spec (spec/system/ui/sheet_component_spec.rb in the
# app) — the render harness CANNOT exercise JS, so here we assert the static
# <dialog> scaffolding the controller relies on (a closed native dialog with full ARIA).
class SheetRenderTest < ViewComponent::TestCase
  def test_renders_a_native_dialog_with_modal_semantics
    render_inline(UI::SheetComponent.new(title: "Filters"))

    assert_selector "dialog[role='dialog'][aria-modal='true']", visible: :all
  end

  def test_title_is_the_accessible_name_via_aria_labelledby
    render_inline(UI::SheetComponent.new(title: "Filters", id: "s1"))

    assert_selector "dialog[aria-labelledby='s1-title']", visible: :all
    assert_selector "h2#s1-title", text: "Filters", visible: :all
  end

  def test_description_wires_aria_describedby
    render_inline(UI::SheetComponent.new(title: "T", id: "s2", description: "Refine your results."))

    assert_selector "dialog[aria-describedby='s2-description']", visible: :all
    assert_selector "p#s2-description", text: "Refine your results.", visible: :all
  end

  def test_omits_aria_describedby_without_a_description
    render_inline(UI::SheetComponent.new(title: "T", id: "s3"))

    assert_no_selector "dialog[aria-describedby]", visible: :all
  end

  def test_default_side_right_sets_leave_transform
    render_inline(UI::SheetComponent.new(title: "T"))

    assert_selector "[data-controller='modal'][data-modal-leave-transform-value='translateX(100%)']", visible: :all
  end

  def test_side_left_sets_leave_transform
    render_inline(UI::SheetComponent.new(title: "T", side: :left))

    assert_selector "[data-modal-leave-transform-value='translateX(-100%)']", visible: :all
  end

  def test_side_top_sets_leave_transform
    render_inline(UI::SheetComponent.new(title: "T", side: :top))

    assert_selector "[data-modal-leave-transform-value='translateY(-100%)']", visible: :all
  end

  def test_side_bottom_sets_leave_transform
    render_inline(UI::SheetComponent.new(title: "T", side: :bottom))

    assert_selector "[data-modal-leave-transform-value='translateY(100%)']", visible: :all
  end

  def test_right_panel_has_right_edge_class
    render_inline(UI::SheetComponent.new(title: "T", side: :right))

    assert_selector "[data-modal-target='panel'].right-0", visible: :all
  end

  def test_left_panel_has_left_edge_class
    render_inline(UI::SheetComponent.new(title: "T", side: :left))

    assert_selector "[data-modal-target='panel'].left-0", visible: :all
  end

  def test_fail_loud_on_unknown_side
    assert_raises(ArgumentError) do
      UI::SheetComponent.new(title: "T", side: :diagonal)
    end
  end

  def test_renders_an_accessible_close_button_wired_to_the_controller
    render_inline(UI::SheetComponent.new(title: "T"))

    assert_selector "button[type='button'][aria-label='Close'][data-action~='click->modal#close']", visible: :all
  end

  def test_renders_with_aaa_tokens
    render_inline(UI::SheetComponent.new(title: "T"))

    assert_selector "[data-modal-target='panel'].bg-surface-overlay", visible: :all
    assert_selector "h2.text-text-heading", visible: :all
  end

  def test_wrapper_false_renders_only_the_dialog
    render_inline(UI::SheetComponent.new(title: "T", wrapper: false))

    assert_no_selector "[data-controller='modal']", visible: :all
    assert_selector "dialog[role='dialog']", visible: :all
  end

  def test_footer_slot_renders_in_a_footer_area
    render_inline(UI::SheetComponent.new(title: "T")) do |sheet|
      sheet.with_footer { "Apply" }
    end

    assert_text "Apply"
  end
end
