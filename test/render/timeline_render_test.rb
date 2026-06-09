# frozen_string_literal: true

require "render_test_helper"
load_component "timeline", "timeline_component.rb.tt"

# STRUCTURE-only render specs. The app 0b preview-host spec proves AAA contrast in a
# real browser; here we assert the semantic scaffolding: an ordered <ol> of <li>
# events, decorative dots/connector marked aria-hidden, AAA tokens, the time as
# perceivable text (<time>, optionally with a machine-readable datetime), and
# caller-class merge.
class TimelineRenderTest < ViewComponent::TestCase
  def test_renders_an_ordered_list_of_li_events
    render_inline(UI::TimelineComponent.new) do |t|
      t.with_item(date: "Jan 2025", title: "Started")
      t.with_item(date: "Feb 2025", title: "Shipped")
    end

    assert_selector "ol > li", text: "Started"
    assert_selector "ol > li", text: "Shipped"
  end

  # The sequence is announced as an ordered list; the connector is the <ol> border.
  def test_ol_uses_aaa_border_token
    render_inline(UI::TimelineComponent.new)

    assert_selector "ol.border-l.border-border"
  end

  def test_marker_dot_is_decorative
    render_inline(UI::TimelineComponent.new) { |t| t.with_item(title: "Event") }

    assert_selector "li span.rounded-full[aria-hidden='true']"
  end

  def test_event_time_renders_as_perceivable_text
    render_inline(UI::TimelineComponent.new) { |t| t.with_item(date: "Mar 2025", title: "Event") }

    assert_selector "li time", text: "Mar 2025"
  end

  def test_datetime_attribute_is_machine_readable_when_supplied
    render_inline(UI::TimelineComponent.new) do |t|
      t.with_item(date: "Mar 2025", datetime: "2025-03", title: "Event")
    end

    assert_selector "li time[datetime='2025-03']", text: "Mar 2025"
  end

  def test_time_uses_the_aaa_muted_token
    render_inline(UI::TimelineComponent.new) { |t| t.with_item(date: "Mar 2025", title: "Event") }

    assert_selector "li time.text-text-muted"
  end

  def test_default_dot_uses_a_semantic_fill
    render_inline(UI::TimelineComponent.new) { |t| t.with_item(title: "Event") }

    assert_selector "li span.bg-interactive[aria-hidden='true']"
  end

  # Semantic tokens only — no raw palette (the pre-harden bug used bg-green-500 etc.).
  def test_signal_variants_use_semantic_tokens
    render_inline(UI::TimelineComponent.new) do |t|
      t.with_item(title: "Ok", variant: :success)
      t.with_item(title: "Bad", variant: :warning)
    end

    assert_selector "li span.bg-success[aria-hidden='true']"
    assert_selector "li span.bg-warning[aria-hidden='true']"
  end

  def test_destructive_is_an_alias_for_danger
    render_inline(UI::TimelineComponent.new) { |t| t.with_item(title: "Removed", variant: :destructive) }

    assert_selector "li span.bg-danger[aria-hidden='true']"
  end

  def test_unknown_variant_raises_outside_production
    error = assert_raises(ArgumentError) do
      render_inline(UI::TimelineComponent.new) { |t| t.with_item(title: "X", variant: :neon) }
    end

    assert_match(/unknown variant :neon/, error.message)
  end

  def test_description_and_block_body_both_render
    render_inline(UI::TimelineComponent.new) do |t|
      t.with_item(title: "Event", description: "Some detail") { "<em>extra</em>".html_safe }
    end

    assert_selector "li p", text: "Some detail"
    assert_selector "li em", text: "extra"
  end

  def test_merges_caller_classes_on_ol_and_li
    render_inline(UI::TimelineComponent.new(class: "max-w-md")) { |t| t.with_item(title: "E", class: "pb-2") }

    assert_selector "ol.max-w-md"
    assert_selector "li.pb-2"
  end
end
