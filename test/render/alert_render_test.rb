# frozen_string_literal: true

require "render_test_helper"
load_component "alert", "alert_component.rb.tt"

class AlertRenderTest < ViewComponent::TestCase
  def test_default_variant_is_a_polite_status_region
    render_inline(UI::AlertComponent.new(title: "Heads up"))

    assert_selector "div[role='status'][aria-live='polite']", text: "Heads up"
  end

  def test_destructive_variant_is_an_assertive_alert_region
    render_inline(UI::AlertComponent.new(variant: :destructive, title: "Couldn't save"))

    assert_selector "div[role='alert'][aria-live='assertive']", text: "Couldn't save"
  end

  # AAA semantic tokens (the design-token guarantee), not raw Tailwind:
  def test_renders_with_aaa_tokens
    render_inline(UI::AlertComponent.new(title: "X"))

    assert_selector "div.bg-surface-raised"
    assert_selector "div.text-text-body"
  end

  def test_renders_title_and_description_slots
    render_inline(UI::AlertComponent.new(variant: :destructive)) do |alert|
      alert.with_alert_title { "2 errors" }
      alert.with_alert_description { "Title can't be blank" }
    end

    assert_selector "h5", text: "2 errors"
    assert_selector "div[data-slot='alert-description']", text: "Title can't be blank"
    # AAA regression guard: destructive uses text-danger (not text-danger/90).
    assert_selector "div.text-danger"
  end

  def test_unknown_variant_raises
    assert_raises(ArgumentError) do
      render_inline(UI::AlertComponent.new(variant: :bogus))
    end
  end
end
