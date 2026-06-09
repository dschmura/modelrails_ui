# frozen_string_literal: true

require "render_test_helper"
load_component "iframe", "iframe_component.rb.tt"

class IframeRenderTest < ViewComponent::TestCase
  SRC = "https://www.openstreetmap.org/export/embed.html"

  def test_renders_iframe_with_src_title_and_lazy_loading
    render_inline(UI::IframeComponent.new(src: SRC, title: "Map of the office"))

    assert_selector "iframe[src='#{SRC}'][title='Map of the office'][loading='lazy']", visible: :all
  end

  # title is the iframe's accessible name — a title-less iframe is a hard WCAG failure.
  def test_requires_a_title
    assert_raises(ArgumentError) { UI::IframeComponent.new(src: SRC, title: nil) }
  end

  # Unlike image's alt, there is no "decorative" iframe — a blank title fails loud.
  def test_blank_title_fails_loud
    assert_raises(ArgumentError) { UI::IframeComponent.new(src: SRC, title: "   ") }
  end

  # AAA semantic tokens, not raw values: w-full + border-0 (no raw color/hex).
  def test_renders_with_aaa_tokens
    render_inline(UI::IframeComponent.new(src: SRC, title: "Map of the office"))

    assert_selector "iframe.w-full.border-0", visible: :all
  end

  # aspect wraps the iframe in a ratio div and the iframe fills it (h-full).
  def test_responsive_aspect_wrapper
    render_inline(UI::IframeComponent.new(src: SRC, title: "Demo video", aspect: "16/9"))

    assert_selector "div[style*='aspect-ratio: 16/9'].overflow-hidden iframe.h-full", visible: :all
  end

  def test_invalid_loading_falls_back_to_lazy
    render_inline(UI::IframeComponent.new(src: SRC, title: "Map", loading: :bogus))

    assert_selector "iframe[loading='lazy']", visible: :all
  end

  # sandbox is on by default with strict tokens; pass-through attrs reach the tag.
  def test_default_sandbox_and_passthrough_attrs
    render_inline(UI::IframeComponent.new(src: SRC, title: "Map", allow: "fullscreen"))

    assert_selector "iframe[sandbox*='allow-scripts'][allow='fullscreen']", visible: :all
  end

  def test_merges_caller_classes
    render_inline(UI::IframeComponent.new(src: SRC, title: "Map", class: "rounded-lg"))

    assert_selector "iframe.rounded-lg", visible: :all
  end
end
