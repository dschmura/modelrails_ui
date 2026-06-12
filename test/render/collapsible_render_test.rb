# frozen_string_literal: true

require "render_test_helper"
load_component "collapsible", "collapsible_component.rb.tt"

# STRUCTURE-only render specs. Collapsible is a native <details>/<summary> (the
# browser owns the disclosure semantics + keyboard); the app 0b proves it axe-AAA
# in a real browser. Here we assert the scaffolding + the AAA focus contract.
class CollapsibleRenderTest < ViewComponent::TestCase
  def render_collapsible(open: false)
    render_inline(UI::CollapsibleComponent.new(open: open)) do |c|
      c.with_trigger { "Details" }
      "Hidden body"
    end
  end

  def test_renders_a_details_with_a_summary
    render_collapsible

    assert_selector "details summary", text: "Details"
    # Collapsed <details> content is hidden to Capybara's static driver — assert it exists.
    assert_selector "details > div", text: "Hidden body", visible: :all
  end

  def test_open_renders_expanded
    render_collapsible(open: true)

    assert_selector "details[open] summary", text: "Details"
  end

  def test_closed_by_default
    render_collapsible

    assert_no_selector "details[open]"
  end

  # The headline AAA fix: the summary's focus indicator is the offset `focus-ring`
  # outline utility — NOT a box-shadow ring (clipped by overflow-hidden ancestors,
  # gone in forced-colors mode — a 2.4.7 failure).
  def test_summary_carries_the_aaa_focus_ring
    render_collapsible

    assert_selector "summary.focus-ring"
  end

  # Regression guard: the ring anti-pattern must never come back.
  def test_summary_has_no_box_shadow_ring_or_outline_none
    render_collapsible
    html = page.native.to_html

    refute_includes html, "focus-visible:ring-"
    refute_includes html, "outline-none"
  end

  # The native webkit disclosure marker is hidden so the caller-supplied trigger
  # owns the open/closed affordance.
  def test_hides_the_native_webkit_marker
    render_collapsible

    assert_selector "summary[class*='webkit-details-marker']"
  end

  # html_attrs pass through onto the <details> root, matching the sibling components.
  def test_passes_through_html_attrs_onto_the_root
    render_inline(UI::CollapsibleComponent.new(id: "faq", class: "mt-4")) do |c|
      c.with_trigger { "More" }
      "Body"
    end

    assert_selector "details#faq.mt-4"
  end
end
