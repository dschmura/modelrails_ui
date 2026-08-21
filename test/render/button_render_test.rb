# frozen_string_literal: true

require "render_test_helper"
load_component "button", "button_component.rb.tt"

class ButtonRenderTest < ViewComponent::TestCase
  def test_primary_renders_correct_tag_and_text
    render_inline(UI::ButtonComponent.new("Save changes", variant: :primary))

    assert_selector "button[type='button']", text: "Save changes"
  end

  # The component selects a canonical .btn-* class; the stylesheet owns what that class
  # looks like. Asserting the utilities behind it here is what allowed COMBOS and the CSS
  # to drift apart (#101), so these assert the class the component chose.
  def test_primary_renders_the_canonical_button_class
    render_inline(UI::ButtonComponent.new("Save changes", variant: :primary))

    assert_selector "button.btn-primary"
  end

  def test_href_renders_anchor
    render_inline(UI::ButtonComponent.new("Home", href: "/", variant: :primary))

    assert_selector "a[href='/']", text: "Home"
  end

  # `destructive` is a non-breaking alias for the canonical `danger` — identical render.
  def test_destructive_alias_renders_like_danger
    render_inline(UI::ButtonComponent.new("Delete", variant: :danger))
    danger_class = page.find("button")[:class]

    render_inline(UI::ButtonComponent.new("Delete", variant: :destructive))
    destructive_class = page.find("button")[:class]

    assert_equal danger_class, destructive_class
  end

  def test_unknown_variant_raises
    assert_raises(ArgumentError) do
      render_inline(UI::ButtonComponent.new("X", variant: :bogus))
    end
  end

  # --- B2 two-axis (variant × tone) + A8 :icon size ---------------------------

  # Back-compat: every legacy flat `variant:` value still renders its marker class
  # (the shim translates the old enum to a (variant, tone) cell — byte-identical output).
  {
    primary: "btn-primary",
    secondary: "btn-secondary",
    danger: "btn-danger",
    destructive: "btn-danger",
    text: "btn-text-interactive",
    text_interactive: "btn-text-interactive",
    text_danger: "btn-text-danger"
  }.each do |legacy, marker|
    define_method("test_legacy_variant_#{legacy}_still_renders") do
      render_inline(UI::ButtonComponent.new("Go", variant: legacy))

      assert_selector "button.#{marker.tr(" ", ".")}"
    end
  end

  def test_two_axis_solid_primary_matches_legacy_primary
    render_inline(UI::ButtonComponent.new("Go", variant: :solid, tone: :primary))

    assert_selector "button.btn-primary"
  end

  def test_two_axis_text_danger
    render_inline(UI::ButtonComponent.new("Go", variant: :text, tone: :danger))

    assert_selector "button.btn-text-danger"
  end

  def test_two_axis_outline_neutral_matches_legacy_secondary
    render_inline(UI::ButtonComponent.new("Go", variant: :outline, tone: :neutral))

    assert_selector "button.btn-secondary"
  end

  # Unproven (variant, tone) cell — raises in dev/test (the AAA combo-guard:
  # a new fill is an untested text-on-* pairing).
  def test_unproven_cell_raises_in_dev
    assert_raises(ArgumentError) do
      render_inline(UI::ButtonComponent.new("Go", variant: :solid, tone: :neutral))
    end
  end

  # A8: `size: :icon` is a 44×44 square (drop horizontal padding, add min-w; min-h
  # is already carried by the .btn-* classes).
  def test_size_icon_is_a_44px_square
    render_inline(UI::ButtonComponent.new(variant: :solid, tone: :primary, size: :icon))

    assert_selector "button.px-0"
    assert_selector 'button.min-w-\\[var\\(--form-input-height\\)\\]'
  end

  # Behavioral proof of the tailwind_merge-backed `cn`: a `class:` passthrough
  # must OVERRIDE a conflicting base utility. The filled base is `rounded-md`;
  # passing `class: "rounded-full"` must win, and `rounded-md` must be dropped.
  def test_class_passthrough_overrides_conflicting_base_utility
    render_inline(UI::ButtonComponent.new("X", variant: :primary, class: "rounded-full"))

    assert_selector "button.rounded-full"
    refute_selector "button.rounded-md"
  end
end
