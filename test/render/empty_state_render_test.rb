# frozen_string_literal: true

require "render_test_helper"
load_component "empty_state", "empty_state_component.rb.tt"

class EmptyStateRenderTest < ViewComponent::TestCase
  def render_empty(**opts, &block)
    render_inline(UI::EmptyStateComponent.new(title: "No projects yet", **opts), &block)
  end

  def test_renders_the_title
    render_empty

    assert_selector "[data-slot='empty-state-title']", text: "No projects yet"
  end

  def test_description_is_optional_and_absent_by_default
    render_empty

    assert_no_selector "[data-slot='empty-state-description']"
  end

  def test_description_renders_when_given
    render_empty(description: "Create one to get started.")

    assert_selector "[data-slot='empty-state-description']", text: "Create one to get started."
  end

  # The title is a <p>, NOT a heading: an empty state can appear anywhere on a page,
  # so emitting an h2/h3 would inject a heading at an arbitrary level and break the
  # outline for anyone navigating by headings.
  def test_the_title_is_not_a_heading
    render_empty

    assert_selector "p[data-slot='empty-state-title']"
    assert_no_selector "h1, h2, h3, h4, h5, h6"
  end

  # --- variants -------------------------------------------------------------

  def test_default_variant_is_the_dashed_well
    render_empty

    assert_selector "div.border-dashed.border-border"
  end

  # bg-surface is the PAGE; a bordered container uses bg-surface-raised
  # (docs/design-tokens.md), which the app's hand-rolled version got wrong.
  def test_outlined_variant_is_a_raised_card_not_the_page_surface
    render_empty(variant: :outlined)

    assert_selector "div.bg-surface-raised.border-border"
    assert_no_selector "div.bg-surface:not(.bg-surface-raised)"
  end

  def test_plain_variant_has_no_chrome
    render_empty(variant: :plain)

    assert_no_selector "div.border-dashed"
    assert_no_selector "div[class*='border-border']"
  end

  def test_unknown_variant_fails_loud
    error = assert_raises(ArgumentError) { render_empty(variant: :fancy) }

    assert_match(/unknown variant :fancy/, error.message)
  end

  # --- slots ----------------------------------------------------------------

  def test_icon_slot_is_absent_by_default
    render_empty

    assert_no_selector "svg"
  end

  def test_icon_slot_renders_and_is_styled_by_the_container
    render_inline(UI::EmptyStateComponent.new(title: "No projects yet")) do |c|
      c.with_icon { "<svg aria-hidden='true'></svg>".html_safe }
    end

    assert_selector "svg"
    assert_selector "div[class*='[&>svg]:text-text-muted']"
  end

  def test_action_slot_renders_inside_its_own_region
    render_inline(UI::EmptyStateComponent.new(title: "No projects yet")) do |c|
      c.with_action { "<a href='/projects/new'>New project</a>".html_safe }
    end

    assert_selector "[data-slot='empty-state-action'] a[href='/projects/new']", text: "New project"
  end

  def test_action_region_is_absent_when_no_action_is_given
    render_empty

    assert_no_selector "[data-slot='empty-state-action']"
  end

  # --- passthrough ----------------------------------------------------------
  #
  # The markdowndocs no-results block is toggled by a Stimulus controller, so it
  # needs both a data target and a caller class to survive.

  def test_caller_class_merges_without_dropping_the_base
    render_empty(class: "hidden")

    assert_selector "div.hidden.text-center"
  end

  def test_caller_data_attributes_reach_the_container
    render_empty(data: {docs_search_target: "noResults"})

    assert_selector "div[data-docs-search-target='noResults']"
  end
end
