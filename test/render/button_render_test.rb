# frozen_string_literal: true

require "render_test_helper"
load_component "button", "button_component.rb.tt"

class ButtonRenderTest < ViewComponent::TestCase
  def test_primary_renders_correct_tag_and_text
    render_inline(UI::ButtonComponent.new("Save changes", variant: :primary))

    assert_selector "button[type='button']", text: "Save changes"
  end

  # AAA semantic tokens (the design-token guarantee), not raw Tailwind:
  def test_primary_renders_with_aaa_tokens
    render_inline(UI::ButtonComponent.new("Save changes", variant: :primary))

    assert_selector "button.bg-interactive"
    assert_selector "button.text-text-on-interactive"
    assert_selector "button.focus\\:ring-interactive-focus"
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

  # Behavioral proof of the tailwind_merge-backed `cn`: a `class:` passthrough
  # must OVERRIDE a conflicting base utility. The filled base is `rounded-md`;
  # passing `class: "rounded-full"` must win, and `rounded-md` must be dropped.
  def test_class_passthrough_overrides_conflicting_base_utility
    render_inline(UI::ButtonComponent.new("X", variant: :primary, class: "rounded-full"))

    assert_selector "button.rounded-full"
    refute_selector "button.rounded-md"
  end
end
