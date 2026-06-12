# frozen_string_literal: true

require "render_test_helper"
# The item must be defined before the parent renders it (parent's call → render(item)).
load_component "accordion", "accordion_item_component.rb.tt"
load_component "accordion", "accordion_component.rb.tt"

# STRUCTURE-only render specs. Accordion is native <details>/<summary> (the browser
# owns the disclosure semantics + keyboard); the app 0b proves it axe-AAA in a real
# browser. Here we assert the scaffolding + the AAA focus contract.
class AccordionRenderTest < ViewComponent::TestCase
  def render_two_items
    render_inline(UI::AccordionComponent.new(items: [
      {title: "First", content: "One"},
      {title: "Second", content: "Two", open: true}
    ]))
  end

  def test_renders_a_details_with_summary_per_item
    render_two_items

    assert_selector "details summary", text: "First"
    assert_selector "details summary", text: "Second"
    # Collapsed <details> content is hidden to Capybara's static driver — assert it exists.
    assert_selector "details > div", text: "One", visible: :all
  end

  def test_open_item_renders_expanded
    render_two_items

    assert_selector "details[open] summary", text: "Second"
    assert_no_selector "details[open] summary", text: "First"
  end

  # The headline AAA fix: the summary's focus indicator is the offset `focus-ring`
  # outline utility — NOT a box-shadow ring (clipped by overflow-hidden ancestors,
  # gone in forced-colors mode — a 2.4.7 failure).
  def test_summary_carries_the_aaa_focus_ring
    render_two_items

    assert_selector "summary.focus-ring"
  end

  # Regression guard: the ring anti-pattern must never come back.
  def test_summary_has_no_box_shadow_ring_or_outline_none
    render_two_items
    html = page.native.to_html

    refute_includes html, "focus-visible:ring-"
    refute_includes html, "outline-none"
  end

  # The chevron conveys nothing the native disclosure doesn't — it is decorative.
  def test_chevron_is_decorative
    render_two_items

    assert_selector "summary svg[aria-hidden='true']"
  end

  # The native webkit disclosure marker is hidden so it doesn't double up with the chevron.
  def test_hides_the_native_webkit_marker
    render_two_items

    assert_selector "summary[class*='webkit-details-marker']"
  end

  # `exclusive: true` is progressive enhancement: opening one closes the rest via the
  # `accordion` Stimulus controller. Default has no controller (items act independently).
  def test_exclusive_mode_wires_the_accordion_controller
    render_inline(UI::AccordionComponent.new(exclusive: true, items: [{title: "A", content: "a"}]))

    assert_selector "div[data-controller='accordion'][data-action='click->accordion#toggle']"
  end

  def test_non_exclusive_has_no_controller
    render_inline(UI::AccordionComponent.new(items: [{title: "A", content: "a"}]))

    assert_no_selector "div[data-controller]"
  end

  # Block slot API renders alongside / instead of the array shorthand.
  def test_renders_slot_items
    render_inline(UI::AccordionComponent.new) do |acc|
      acc.with_item(title: "Slotted") { "Body" }
    end

    assert_selector "details summary", text: "Slotted"
    assert_selector "details > div", text: "Body", visible: :all
  end

  # html_attrs pass through onto the wrapper, matching the sibling components.
  def test_passes_through_html_attrs_onto_the_wrapper
    render_inline(UI::AccordionComponent.new(items: [{title: "A", content: "a"}], id: "faq", class: "mt-4"))

    assert_selector "div#faq.mt-4.w-full"
  end
end
