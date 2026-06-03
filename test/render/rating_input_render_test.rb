# frozen_string_literal: true

require "render_test_helper"
load_component "rating_input", "rating_input_component.rb.tt"

# STRUCTURE-only render tests. The Stimulus `rating` controller's runtime
# behavior — hover preview, click-to-select, and keyboard interaction — is NOT
# exercised here; that is verified by the app's 0b Playwright browser spec.
# These tests assert the rendered HTML contract: group name, star buttons,
# per-star labels, 44px targets, the semantic warning token, and the hidden input.
class RatingInputRenderTest < ViewComponent::TestCase
  def test_renders_a_named_group_container
    render_inline(UI::RatingInputComponent.new(value: 3))

    # The star-button group must expose an accessible name so assistive tech
    # announces it as a coherent group (default "Rating").
    assert_selector "[role='group'][aria-label='Rating']"
  end

  def test_group_label_is_overridable
    render_inline(UI::RatingInputComponent.new(value: 3, label: "Overall quality"))

    assert_selector "[role='group'][aria-label='Overall quality']"
  end

  def test_renders_max_star_buttons_each_with_a_per_star_label
    render_inline(UI::RatingInputComponent.new(value: 2, max: 5))

    assert_selector "button[type='button']", count: 5
    (1..5).each do |i|
      assert_selector "button[type='button'][aria-label='Rate #{i} of 5']"
    end
  end

  def test_each_star_button_meets_the_44px_target_size
    render_inline(UI::RatingInputComponent.new(value: 0, max: 5))

    # AAA 2.5.5: each star is a >=44px hit target even though the visual star is 24px.
    assert_selector "button[type='button'].min-h-11.min-w-11", count: 5
  end

  def test_filled_stars_use_the_semantic_warning_token
    render_inline(UI::RatingInputComponent.new(value: 3, max: 5))

    # Stars are graphic icons (WCAG 1.4.11 → 3:1); the AAA-tuned warning-icon
    # token clears that easily. Filled = index <= value.
    assert_selector "button.text-warning-icon", count: 3
  end

  def test_empty_stars_use_the_muted_text_token
    render_inline(UI::RatingInputComponent.new(value: 3, max: 5))

    assert_selector "button.text-text-muted", count: 2
  end

  def test_never_emits_the_raw_yellow_color
    render_inline(UI::RatingInputComponent.new(value: 5, max: 5))

    # Regression guard: the raw Tailwind color text-yellow-400 (a token violation)
    # must never appear — filled stars use the semantic warning token instead.
    refute_selector ".text-yellow-400"
  end

  def test_name_emits_a_hidden_input_carrying_the_value
    render_inline(UI::RatingInputComponent.new(value: 4, max: 5, name: "review[rating]"))

    assert_selector "input[type='hidden'][name='review[rating]'][value='4']", visible: :all
  end

  def test_no_name_omits_the_hidden_input
    render_inline(UI::RatingInputComponent.new(value: 4, max: 5))

    assert_no_selector "input[type='hidden']", visible: :all
  end

  def test_value_is_clamped_to_the_max
    render_inline(UI::RatingInputComponent.new(value: 99, max: 5, name: "stars"))

    assert_selector "input[type='hidden'][name='stars'][value='5']", visible: :all
  end
end
