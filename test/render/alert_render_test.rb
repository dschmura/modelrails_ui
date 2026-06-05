# frozen_string_literal: true

require "render_test_helper"
load_component "alert", "alert_component.rb.tt"

class AlertRenderTest < ViewComponent::TestCase
  def test_default_variant_is_a_polite_status_region
    render_inline(UI::AlertComponent.new(title: "Heads up"))

    assert_selector "div[role='status'][aria-live='polite']", text: "Heads up"
  end

  def test_danger_variant_is_an_assertive_alert_on_the_danger_surface
    render_inline(UI::AlertComponent.new(variant: :danger, title: "Couldn't save"))

    assert_selector "div[role='alert'][aria-live='assertive'].bg-danger-surface", text: "Couldn't save"
  end

  # `destructive` is a non-breaking alias for the canonical `danger` — it must
  # render an identical root (same role + tinted danger surface).
  def test_destructive_alias_renders_identically_to_danger
    render_inline(UI::AlertComponent.new(variant: :destructive, title: "Couldn't save"))

    assert_selector "div[role='alert'][aria-live='assertive'].bg-danger-surface", text: "Couldn't save"
  end

  def test_warning_variant_is_a_polite_status_on_the_warning_surface
    render_inline(UI::AlertComponent.new(variant: :warning, title: "Heads up"))

    assert_selector "div[role='status'][aria-live='polite'].bg-warning-surface", text: "Heads up"
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

  # html_attrs pass through onto the root, matching the sibling components.
  def test_passes_through_html_attrs_onto_the_root
    render_inline(UI::AlertComponent.new(title: "Heads up", id: "save-alert", data: {testid: "alert"}))

    assert_selector "div#save-alert[role='status'][data-testid='alert']"
  end

  # A caller-supplied class merges onto the root without clobbering the variant tokens.
  def test_merges_caller_class_onto_the_root
    render_inline(UI::AlertComponent.new(title: "Heads up", class: "mt-4"))

    assert_selector "div.mt-4.bg-surface-raised"
  end
end
