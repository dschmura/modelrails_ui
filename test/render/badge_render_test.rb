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

  # The canonical `danger` signal uses the TINTED treatment (soft danger-surface +
  # saturated text-danger + danger-border), not a solid fill. Never raw palette /
  # text-white; focus ring is the uniform focus-ring utility.
  def test_danger_uses_tinted_surface
    render_inline(UI::BadgeComponent.new("Error", variant: :danger))

    assert_selector "span.bg-danger-surface.text-danger.border-danger-border"
    assert_selector "span.focus-ring"
    refute_selector "span.text-white"
  end

  # `destructive` is a non-breaking alias for the canonical `danger` — identical fill.
  def test_destructive_alias_renders_as_danger
    render_inline(UI::BadgeComponent.new("Error", variant: :destructive))

    assert_selector "span.bg-danger-surface.text-danger.border-danger-border"
  end

  # Tinted signal chips (only AAA semantic tokens, never raw palette): soft *-surface
  # background + saturated text-<level> + *-border, matching the alert + toast cards.
  def test_info_uses_tinted_surface
    render_inline(UI::BadgeComponent.new("Note", variant: :info))

    assert_selector "span.bg-info-surface.text-info.border-info-border"
    refute_selector "span.text-white"
  end

  def test_success_uses_tinted_surface
    render_inline(UI::BadgeComponent.new("Done", variant: :success))

    assert_selector "span.bg-success-surface.text-success.border-success-border"
    refute_selector "span.text-white"
  end

  # warning is tinted (soft amber surface + dark amber text), NOT a solid bg-warning
  # fill (amber-900 = a dark brown chip) and NOT text-text-heading (low-contrast).
  def test_warning_uses_tinted_surface
    render_inline(UI::BadgeComponent.new("Careful", variant: :warning))

    assert_selector "span.bg-warning-surface.text-warning.border-warning-border"
    refute_selector "span.text-text-heading"
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
