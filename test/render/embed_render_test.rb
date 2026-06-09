# frozen_string_literal: true

require "render_test_helper"
load_component "embed", "embed_component.rb.tt"

class EmbedRenderTest < ViewComponent::TestCase
  def test_youtube_iframe_has_accessible_title_and_lazy_loading
    render_inline(UI::EmbedComponent.new(url: "https://youtu.be/dQw4w9WgXcQ"))

    assert_selector "iframe[title='YouTube video'][loading='lazy']", visible: :all
    assert_selector "iframe[src*='youtube.com/embed/dQw4w9WgXcQ']", visible: :all
  end

  def test_caller_title_overrides_default
    render_inline(UI::EmbedComponent.new(url: "https://youtu.be/abc", title: "Launch keynote"))

    assert_selector "iframe[title='Launch keynote']", visible: :all
  end

  def test_iframe_title_is_never_blank
    render_inline(UI::EmbedComponent.new(url: "https://vimeo.com/148751763"))

    assert_selector "iframe[title]", visible: :all
    refute_empty page.find("iframe", visible: :all)[:title]
  end

  def test_unsupported_url_renders_a_danger_message
    render_inline(UI::EmbedComponent.new(url: "https://example.com/nope"))

    assert_selector "p.text-danger"
  end
end
