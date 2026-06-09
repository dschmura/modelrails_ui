# frozen_string_literal: true

require "render_test_helper"
load_component "map_area", "map_area_component.rb.tt"

class MapAreaRenderTest < ViewComponent::TestCase
  AREAS = [
    {shape: :rect, coords: "0,0,200,150", href: "/room/1", alt: "Room 1"},
    {shape: :circle, coords: "400,300,50", href: "/room/2", alt: "Room 2"}
  ].freeze

  def render_default(**overrides)
    render_inline(UI::MapAreaComponent.new(
      src: "https://example.com/plan.png", alt: "Floor plan", areas: AREAS, **overrides
    ))
  end

  def test_renders_an_img_with_alt_and_usemap
    render_default

    assert_selector "img[alt='Floor plan'][usemap]"
  end

  def test_renders_a_map_and_one_area_per_hotspot
    render_default

    assert_selector "map area", count: 2
  end

  # WCAG: every linked <area> announces as a named link. No href may ship nameless.
  def test_every_area_has_a_non_blank_alt
    render_default

    page.all("area").each { |area| assert_predicate area["alt"].to_s.strip.length, :positive? }
  end

  # The usemap reference must point at the <map name> or no hotspots resolve.
  def test_usemap_matches_the_map_name
    render_inline(UI::MapAreaComponent.new(
      src: "/p.png", alt: "Plan", areas: AREAS, map_name: "rooms"
    ))

    assert_selector "img[usemap='#rooms']"
    assert_selector "map[name='rooms']"
  end

  # Fail loud: an href with no accessible name is an unlabeled control.
  def test_raises_when_a_linked_area_has_no_alt
    error = assert_raises(ArgumentError) do
      render_inline(UI::MapAreaComponent.new(
        src: "/p.png", alt: "Plan",
        areas: [{shape: :rect, coords: "0,0,1,1", href: "/x"}]
      ))
    end

    assert_match(/alt/, error.message)
  end

  # A non-interactive area (no href) may omit alt without raising.
  def test_allows_an_area_without_href_to_omit_alt
    render_inline(UI::MapAreaComponent.new(
      src: "/p.png", alt: "Plan",
      areas: [{shape: :default}]
    ))

    assert_selector "map area"
  end

  # AAA token guarantee: the wrapper carries only layout (no raw color), and the
  # design-token layout class survives. Caller classes merge onto the wrapper.
  def test_merges_caller_classes_on_the_wrapper
    render_default(class: "w-full")

    assert_selector "div.relative.inline-block.w-full"
  end
end
