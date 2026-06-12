# frozen_string_literal: true

require "render_test_helper"
load_component "rating", "rating_component.rb.tt"

# STRUCTURE-only render specs. Rating is a STATIC, read-only star display: a single
# labelled graphic (role="img" + i18n aria-label) wrapping decorative star glyphs.
# The app 0b proves AAA graphic contrast in a real browser; here we assert the
# scaffolding + the accessible-name/value contract + the semantic-token guarantee.
class RatingRenderTest < ViewComponent::TestCase
  def test_renders_a_single_labelled_graphic
    render_inline(UI::RatingComponent.new(value: 3))

    assert_selector "div[role='img']"
  end

  # The whole control exposes its VALUE to AT via the i18n aria-label — color-filled
  # stars alone carry no accessible meaning.
  def test_exposes_value_and_max_as_an_accessible_name
    render_inline(UI::RatingComponent.new(value: 3, max: 5))

    assert_selector "div[role='img'][aria-label='3 out of 5 stars']"
  end

  # A whole-number float value reads as an integer ("3", not "3.0").
  def test_whole_number_value_reads_as_an_integer
    render_inline(UI::RatingComponent.new(value: 3.0))

    assert_selector "div[aria-label='3 out of 5 stars']"
  end

  # A fractional value is preserved in the accessible name.
  def test_fractional_value_is_preserved_in_the_label
    render_inline(UI::RatingComponent.new(value: 3.5))

    assert_selector "div[aria-label='3.5 out of 5 stars']"
  end

  def test_value_is_clamped_to_max
    render_inline(UI::RatingComponent.new(value: 9, max: 5))

    assert_selector "div[aria-label='5 out of 5 stars']"
  end

  # max controls the star count and the accessible-name denominator.
  def test_max_controls_star_count_and_denominator
    render_inline(UI::RatingComponent.new(value: 7, max: 10))

    assert_selector "svg", count: 10
    assert_selector "div[aria-label='7 out of 10 stars']"
  end

  # Filled stars use the AAA-tuned semantic warning-icon token (was raw
  # text-yellow-400); the unfilled outline uses the muted body token.
  def test_filled_stars_use_the_semantic_warning_token
    render_inline(UI::RatingComponent.new(value: 3, max: 5))

    assert_selector "svg.text-warning-icon", count: 3
    assert_selector "svg.text-text-muted", count: 2
  end

  # The decorative star glyphs are hidden from AT — only the wrapping graphic's
  # accessible name announces.
  def test_decorative_stars_are_aria_hidden
    render_inline(UI::RatingComponent.new(value: 2))

    assert_selector "svg[aria-hidden='true']", count: 5
    assert_no_selector "svg[role='img']"
  end

  # Regression guard: the raw palette must never come back.
  def test_no_raw_palette_color
    render_inline(UI::RatingComponent.new(value: 4))
    html = page.native.to_html

    refute_includes html, "text-yellow-400"
    refute_match(/text-(yellow|amber)-\d/, html)
  end

  # html_attrs pass through onto the root <div>, matching the sibling components.
  def test_passes_through_html_attrs_onto_the_root
    render_inline(UI::RatingComponent.new(value: 3, id: "product-rating", data: {testid: "rating"}))

    assert_selector "div#product-rating[data-testid='rating'][role='img']"
  end

  # A caller-supplied class merges onto the root without clobbering the layout classes.
  def test_merges_caller_class_onto_the_root
    render_inline(UI::RatingComponent.new(value: 3, class: "mt-4"))

    assert_selector "div.mt-4.inline-flex"
  end

  # The component wins on its a11y contract: a caller can't clobber role/aria-label.
  def test_component_wins_role_and_aria_label_over_caller
    render_inline(UI::RatingComponent.new(value: 3, role: "presentation", "aria-label": "hijacked"))

    assert_selector "div[role='img'][aria-label='3 out of 5 stars']"
    assert_no_selector "div[role='presentation']"
  end
end
