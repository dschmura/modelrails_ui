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

  def test_unknown_variant_raises
    assert_raises(ArgumentError) do
      render_inline(UI::ButtonComponent.new("X", variant: :bogus))
    end
  end
end
