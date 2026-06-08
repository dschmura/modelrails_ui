# frozen_string_literal: true

require "render_test_helper"
load_component "search_input", "search_input_component.rb.tt"

class SearchInputRenderTest < ViewComponent::TestCase
  def test_renders_a_search_input
    render_inline(UI::SearchInputComponent.new(name: "q"))

    assert_selector "input[type='search']"
  end

  # A search input needs an accessible name. We supply one via aria-label with an
  # i18n default so the control is never unlabelled (placeholder is only a hint).
  def test_has_an_accessible_name_via_aria_label
    render_inline(UI::SearchInputComponent.new(name: "q"))

    label = page.find("input[type='search']")["aria-label"]

    refute_nil label, "search input must carry an accessible name (aria-label)"
    refute_empty label.to_s
  end

  def test_aria_label_is_overridable
    render_inline(UI::SearchInputComponent.new(name: "q", label: "Search products"))

    assert_selector "input[type='search'][aria-label='Search products']"
  end

  # AAA semantic tokens (the design-token guarantee), not raw Tailwind:
  def test_renders_with_aaa_tokens
    render_inline(UI::SearchInputComponent.new(name: "q"))

    assert_selector "input.border-border-strong"
    assert_selector "input.focus-ring"
  end

  # WCAG 2.5.5 target size: the control sits at the 44px floor (h-11).
  def test_meets_44px_target_floor
    render_inline(UI::SearchInputComponent.new(name: "q"))

    assert_selector "input.h-11"
  end

  # The decorative magnifier icon must be hidden from assistive tech.
  def test_icon_is_aria_hidden
    render_inline(UI::SearchInputComponent.new(name: "q"))

    assert_selector "svg[aria-hidden='true']"
  end

  # invalid: drives the server-validation-driven aria-invalid posture.
  def test_invalid_sets_aria_invalid
    render_inline(UI::SearchInputComponent.new(name: "q", invalid: true))

    assert_selector "input[type='search'][aria-invalid='true']"
  end

  def test_not_invalid_by_default
    render_inline(UI::SearchInputComponent.new(name: "q"))

    assert_no_selector "input[aria-invalid='true']"
  end

  def test_describedby_sets_aria_describedby
    render_inline(UI::SearchInputComponent.new(name: "q", describedby: "search_hint"))

    assert_selector "input[type='search'][aria-describedby='search_hint']"
  end

  def test_no_describedby_by_default
    render_inline(UI::SearchInputComponent.new(name: "q"))

    assert_no_selector "input[aria-describedby]"
  end

  def test_required_sets_required_and_aria_required
    render_inline(UI::SearchInputComponent.new(name: "q", required: true))

    assert_selector "input[type='search'][required][aria-required='true']"
  end

  def test_not_required_by_default
    render_inline(UI::SearchInputComponent.new(name: "q"))

    assert_no_selector "input[required]"
  end

  def test_passes_through_name_and_placeholder
    render_inline(UI::SearchInputComponent.new(name: "q", placeholder: "Find a thing…"))

    assert_selector "input[type='search'][name='q'][placeholder='Find a thing…']"
  end

  # The default placeholder is i18n-resolved (falls back to "Search…"), never a
  # hardcoded string — a placeholder is set by default but is only a hint, not a name.
  def test_default_placeholder_is_i18n_resolved
    render_inline(UI::SearchInputComponent.new(name: "q"))

    placeholder = page.find("input[type='search']")["placeholder"]

    refute_nil placeholder
    refute_empty placeholder.to_s
  end
end
