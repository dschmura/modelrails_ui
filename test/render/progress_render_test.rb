# frozen_string_literal: true

require "render_test_helper"
load_component "progress", "progress_component.rb.tt"

class ProgressRenderTest < ViewComponent::TestCase
  def test_renders_progressbar_with_aria_values
    render_inline(UI::ProgressComponent.new(value: 50))

    assert_selector "div[role='progressbar'][aria-valuenow='50'][aria-valuemin='0'][aria-valuemax='100']", visible: :all
  end

  def test_renders_inner_bar
    render_inline(UI::ProgressComponent.new(value: 50))

    assert_selector "div[role='progressbar'] > div.bg-interactive", visible: :all
  end

  def test_label_sets_aria_label
    render_inline(UI::ProgressComponent.new(value: 70, label: "Upload"))

    assert_selector "div[role='progressbar'][aria-label='Upload']", visible: :all
  end

  def test_omits_aria_label_when_no_label
    render_inline(UI::ProgressComponent.new(value: 70))

    assert_no_selector "div[role='progressbar'][aria-label]", visible: :all
  end

  def test_clamps_overflow_value_to_full_width
    render_inline(UI::ProgressComponent.new(value: 150))

    assert_selector "div[role='progressbar'] > div[style*='width: 100']", visible: :all
  end

  def test_clamps_negative_value_to_zero_width
    render_inline(UI::ProgressComponent.new(value: -10))

    assert_selector "div[role='progressbar'] > div[style*='width: 0']", visible: :all
  end

  def test_renders_with_aaa_track_and_bar_tokens
    render_inline(UI::ProgressComponent.new(value: 40))

    assert_selector "div.bg-interactive\\/20", visible: :all
    assert_selector "div.bg-interactive", visible: :all
  end

  def test_merges_caller_classes
    render_inline(UI::ProgressComponent.new(value: 40, class: "max-w-xs"))

    assert_selector "div.max-w-xs", visible: :all
  end
end
