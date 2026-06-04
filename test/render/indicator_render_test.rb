# frozen_string_literal: true

require "render_test_helper"
load_component "indicator", "indicator_component.rb.tt"

class IndicatorRenderTest < ViewComponent::TestCase
  def test_renders_relative_inline_flex_wrapper
    render_inline(UI::IndicatorComponent.new) { "icon" }

    assert_selector "span.relative.inline-flex", visible: :all
  end

  def test_count_renders_in_a_larger_dot
    render_inline(UI::IndicatorComponent.new(count: 3)) { "icon" }

    assert_selector "span.size-5.min-w-5", text: "3", visible: :all
  end

  def test_without_count_renders_a_small_dot
    render_inline(UI::IndicatorComponent.new) { "icon" }

    assert_selector "span.size-2", visible: :all
  end

  def test_variant_tokens_are_semantic
    render_inline(UI::IndicatorComponent.new(variant: :success)) { "x" }

    assert_selector "span.bg-success.text-text-on-interactive", visible: :all

    render_inline(UI::IndicatorComponent.new(variant: :warning)) { "x" }

    assert_selector "span.bg-warning.text-text-heading", visible: :all

    render_inline(UI::IndicatorComponent.new(variant: :destructive)) { "x" }

    assert_selector "span.bg-danger.text-text-on-interactive", visible: :all
  end

  # No raw Tailwind palette — only AAA semantic tokens.
  def test_refutes_raw_palette
    render_inline(UI::IndicatorComponent.new(variant: :success)) { "x" }

    assert_no_selector "span.bg-green-500", visible: :all
    assert_no_selector "span.text-white", visible: :all

    render_inline(UI::IndicatorComponent.new(variant: :warning)) { "x" }

    assert_no_selector "span.bg-yellow-500", visible: :all
  end

  def test_positions
    render_inline(UI::IndicatorComponent.new(position: :bottom_left)) { "x" }

    assert_selector "span.-bottom-1.-left-1", visible: :all
  end

  def test_unknown_variant_raises
    assert_raises(ArgumentError) do
      UI::IndicatorComponent.new(variant: :nope)
    end
  end

  def test_merges_caller_classes
    render_inline(UI::IndicatorComponent.new(class: "align-middle")) { "x" }

    assert_selector "span.align-middle", visible: :all
  end
end
