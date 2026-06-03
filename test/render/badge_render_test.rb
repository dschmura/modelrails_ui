# frozen_string_literal: true

require "render_test_helper"
load_component "badge", "badge_component.rb.tt"

class BadgeRenderTest < ViewComponent::TestCase
  def test_default_renders_span_with_label
    render_inline(UI::BadgeComponent.new("New"))

    assert_selector "span", text: "New"
  end

  # AAA semantic tokens (the design-token guarantee), not raw Tailwind:
  def test_default_renders_with_aaa_tokens
    render_inline(UI::BadgeComponent.new("New"))

    assert_selector "span.bg-interactive"
    assert_selector "span.text-text-on-interactive"
  end

  # Per-surface dark-AAA fix: destructive must use the adaptive text-text-on-interactive
  # token, NOT text-white (white-on-light-pink fails AAA in dark mode).
  def test_destructive_uses_adaptive_on_interactive_token
    render_inline(UI::BadgeComponent.new("Error", variant: :destructive))

    assert_selector "span.bg-danger"
    assert_selector "span.text-text-on-interactive"
    refute_selector "span.text-white"
  end

  def test_href_renders_anchor
    render_inline(UI::BadgeComponent.new("Docs", href: "/docs"))

    assert_selector "a[href='/docs']", text: "Docs"
  end

  def test_unknown_variant_raises
    assert_raises(ArgumentError) do
      render_inline(UI::BadgeComponent.new("X", variant: :bogus))
    end
  end
end
