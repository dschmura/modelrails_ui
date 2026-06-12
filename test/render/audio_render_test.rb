# frozen_string_literal: true

require "render_test_helper"
load_component "audio", "audio_component.rb.tt"

class AudioRenderTest < ViewComponent::TestCase
  def test_renders_audio_with_controls_and_metadata_preload
    render_inline(UI::AudioComponent.new)

    assert_selector "audio[controls][preload='metadata']", visible: :all
  end

  def test_renders_source_children
    render_inline(UI::AudioComponent.new) do |a|
      a.with_source(src: "/a.mp3", type: "audio/mpeg")
    end

    assert_selector "audio source[src='/a.mp3'][type='audio/mpeg']", visible: :all
  end

  def test_autoplay_implies_muted_is_caller_responsibility_but_flags_render
    render_inline(UI::AudioComponent.new(autoplay: true, muted: true))

    assert_selector "audio[autoplay][muted]", visible: :all
  end

  def test_unknown_preload_raises
    error = assert_raises(ArgumentError) { render_inline(UI::AudioComponent.new(preload: :nope)) }

    assert_match(/preload/, error.message)
  end

  def test_merges_caller_classes
    render_inline(UI::AudioComponent.new(class: "w-full"))

    assert_selector "audio.w-full", visible: :all
  end
end
