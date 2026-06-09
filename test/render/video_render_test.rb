# frozen_string_literal: true

require "render_test_helper"
load_component "video", "video_component.rb.tt"

class VideoRenderTest < ViewComponent::TestCase
  def test_renders_video_with_controls_and_max_width_token
    render_inline(UI::VideoComponent.new)

    assert_selector "video.max-w-full[controls][preload='metadata']", visible: :all
  end

  def test_poster_and_playsinline
    render_inline(UI::VideoComponent.new(poster: "/p.jpg"))

    assert_selector "video[poster='/p.jpg'][playsinline]", visible: :all
  end

  def test_autoplay_forces_muted
    render_inline(UI::VideoComponent.new(autoplay: true))

    assert_selector "video[autoplay][muted]", visible: :all
  end

  def test_renders_source_and_track_children
    render_inline(UI::VideoComponent.new) do |v|
      v.with_source(src: "/v.mp4", type: "video/mp4")
      v.with_track(src: "/en.vtt", kind: :captions, label: "English", srclang: "en", default: true)
    end

    assert_selector "video source[src='/v.mp4'][type='video/mp4']", visible: :all
    assert_selector "video track[src='/en.vtt'][kind='captions'][label='English'][srclang='en'][default]", visible: :all
  end

  def test_unknown_track_kind_raises
    error = assert_raises(ArgumentError) do
      render_inline(UI::VideoComponent.new) { |v| v.with_track(src: "/x.vtt", kind: :subtitels) }
    end

    assert_match(/kind/, error.message)
  end
end
