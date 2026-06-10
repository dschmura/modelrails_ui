# frozen_string_literal: true

require "render_test_helper"
load_component "toggle_group", "toggle_group_component.rb.tt"

# STRUCTURE-only render specs. The selection BEHAVIOUR (one-active-at-a-time vs
# many) lives in the `toggle-group` Stimulus controller; the app 0b proves it
# axe-AAA in a real browser. Here we assert the wrapper scaffolding: the named
# `role="group"`, the controller wiring, the type-value, the accessible-name
# fail-loud contract, and `item_pressed?`.
class ToggleGroupRenderTest < ViewComponent::TestCase
  def test_single_renders_a_named_group_wired_to_the_controller
    render_inline(UI::ToggleGroupComponent.new(type: :single, aria_label: "Text alignment")) { "items" }

    assert_selector "div[role='group'][aria-label='Text alignment']" \
                    "[data-controller='toggle-group'][data-toggle-group-type-value='single']"
  end

  def test_multiple_sets_the_type_value_to_multiple
    render_inline(UI::ToggleGroupComponent.new(type: :multiple, aria_label: "Text style")) { "items" }

    assert_selector "div[role='group'][data-toggle-group-type-value='multiple']"
  end

  def test_accepts_aria_labelledby_as_the_accessible_name
    render_inline(UI::ToggleGroupComponent.new(aria_labelledby: "align-heading")) { "items" }

    assert_selector "div[role='group'][aria-labelledby='align-heading']"
    assert_no_selector "div[aria-label]"
  end

  # A nameless group of toggle buttons is the documented anti-pattern — fail loud.
  def test_fails_loud_without_an_accessible_name
    assert_raises(ArgumentError) do
      UI::ToggleGroupComponent.new
    end
  end

  def test_blank_aria_label_fails_loud
    assert_raises(ArgumentError) do
      UI::ToggleGroupComponent.new(aria_label: "   ")
    end
  end

  # Fail-loud type guard: an unknown type raises rather than silently passing a
  # bogus value through to the controller.
  def test_unknown_type_raises
    assert_raises(ArgumentError) do
      UI::ToggleGroupComponent.new(type: :bogus, aria_label: "x")
    end
  end

  # item_pressed? drives each item's initial pressed state. Single takes a scalar
  # active value; multiple takes an array.
  def test_item_pressed_for_single_value
    component = UI::ToggleGroupComponent.new(type: :single, value: "center", aria_label: "Align")

    assert component.item_pressed?("center")
    assert component.item_pressed?(:center) # symbol coerces to the same string
    refute component.item_pressed?("left")
  end

  def test_item_pressed_for_multiple_values
    component = UI::ToggleGroupComponent.new(type: :multiple, value: %w[bold italic], aria_label: "Style")

    assert component.item_pressed?("bold")
    assert component.item_pressed?("italic")
    refute component.item_pressed?("underline")
  end

  def test_item_pressed_is_false_when_no_value_is_active
    component = UI::ToggleGroupComponent.new(aria_label: "Align")

    refute component.item_pressed?("center")
  end

  # AAA semantic base layout token (the design-token guarantee), not raw Tailwind.
  def test_renders_with_base_layout_tokens
    render_inline(UI::ToggleGroupComponent.new(aria_label: "Align")) { "items" }

    assert_selector "div.inline-flex.gap-1"
  end

  # html_attrs pass through onto the root, matching the sibling components.
  def test_passes_through_html_attrs_onto_the_root
    render_inline(UI::ToggleGroupComponent.new(aria_label: "Align", id: "align-group", data: {testid: "tg"})) { "items" }

    assert_selector "div#align-group[role='group'][data-testid='tg']"
  end

  # A caller-supplied class merges onto the root without clobbering the base layout.
  def test_merges_caller_class_onto_the_root
    render_inline(UI::ToggleGroupComponent.new(aria_label: "Align", class: "mt-4")) { "items" }

    assert_selector "div.mt-4.inline-flex"
  end
end
