# frozen_string_literal: true

require "render_test_helper"
load_component "banner", "banner_component.rb.tt"

class BannerRenderTest < ViewComponent::TestCase
  def test_renders_a_region_landmark_with_the_message
    render_inline(UI::BannerComponent.new("We shipped 2.0!"))

    assert_selector "div[role='region']", text: "We shipped 2.0!"
  end

  def test_region_has_an_i18n_accessible_name
    render_inline(UI::BannerComponent.new("Hi"))

    assert_selector "div[role='region'][aria-label='Announcement']"
  end

  def test_accepts_the_message_via_message_kwarg
    render_inline(UI::BannerComponent.new(message: "Maintenance Sunday"))

    assert_selector "div[role='region']", text: "Maintenance Sunday"
  end

  def test_slot_content_takes_precedence_over_the_message
    render_inline(UI::BannerComponent.new("ignored")) { "From the block" }

    assert_text "From the block"
    assert_no_text "ignored"
  end

  # AAA semantic tokens (the design-token guarantee), not raw blue-50/green-50 etc.
  def test_default_uses_aaa_neutral_tokens
    render_inline(UI::BannerComponent.new("Hi"))

    assert_selector "div.bg-surface-raised.text-text-body"
  end

  # Signal variants use the tinted-surface treatment (bg-*-surface + *-border +
  # text-*), never a solid signal fill.
  def test_signal_variant_uses_tinted_surface_tokens
    render_inline(UI::BannerComponent.new("Heads up", variant: :warning))

    assert_selector "div.bg-warning-surface.border-warning-border.text-warning"
  end

  # Dismiss is a real focusable <button> with an i18n accessible name + focus-ring.
  def test_dismissible_renders_an_accessible_dismiss_button
    render_inline(UI::BannerComponent.new("Cookies", dismissible: true))

    assert_selector "button[type='button'][aria-label='Dismiss']"
  end

  def test_dismiss_button_uses_the_focus_ring_utility
    render_inline(UI::BannerComponent.new("Cookies", dismissible: true))

    assert_selector "button.focus-ring"
  end

  def test_not_dismissible_by_default
    render_inline(UI::BannerComponent.new("Hi"))

    assert_no_selector "button"
  end

  # Fail loud in development/test so a typo'd variant is caught immediately.
  def test_unknown_variant_raises
    error = assert_raises(ArgumentError) { render_inline(UI::BannerComponent.new("x", variant: :nope)) }

    assert_match(/unknown variant/, error.message)
  end

  def test_merges_caller_classes
    render_inline(UI::BannerComponent.new("Hi", class: "mt-4"))

    assert_selector "div.mt-4"
  end
end
