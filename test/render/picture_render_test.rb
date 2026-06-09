# frozen_string_literal: true

require "render_test_helper"
load_component "picture", "picture_component.rb.tt"

class PictureRenderTest < ViewComponent::TestCase
  SRC = "https://example.com/photo.jpg"

  def test_renders_picture_with_sources_and_fallback_img
    render_inline(UI::PictureComponent.new(src: SRC, alt: "A photo")) do |p|
      p.with_source(srcset: "wide.jpg", media: "(min-width: 800px)")
      p.with_source(srcset: "narrow.jpg", media: "(max-width: 799px)")
    end

    assert_selector "picture source[srcset='wide.jpg'][media='(min-width: 800px)']", visible: :all
    assert_selector "picture source[srcset='narrow.jpg']", visible: :all
    assert_selector "picture img[src='#{SRC}'][alt='A photo'][loading='lazy']", visible: :all
  end

  def test_source_emits_type_for_format_fallback
    render_inline(UI::PictureComponent.new(src: SRC, alt: "A photo")) do |p|
      p.with_source(srcset: "photo.avif", type: "image/avif")
    end

    assert_selector "picture source[srcset='photo.avif'][type='image/avif']", visible: :all
  end

  # alt is required — omitting it is a call-site error (Ruby fail-loud), the same
  # contract the image primitive enforces. A <picture>'s name comes from its <img>.
  def test_alt_is_required
    assert_raises(ArgumentError) { UI::PictureComponent.new(src: SRC) }
  end

  # Empty alt is the correct decorative signal — it must render alt="".
  def test_decorative_empty_alt
    render_inline(UI::PictureComponent.new(src: SRC, alt: ""))

    assert_selector "picture img[alt='']", visible: :all
  end

  def test_invalid_loading_falls_back_to_lazy
    render_inline(UI::PictureComponent.new(src: SRC, alt: "A photo", loading: :bogus))

    assert_selector "picture img[loading='lazy']", visible: :all
  end

  # AAA token discipline: the fallback img uses the BASE utility (no raw hex / color),
  # and caller classes merge onto the <img>.
  def test_merges_caller_classes_onto_img
    render_inline(UI::PictureComponent.new(src: SRC, alt: "A photo", class: "rounded-lg"))

    assert_selector "picture img.max-w-full.rounded-lg", visible: :all
  end

  def test_emits_dimension_attrs_only_when_given
    render_inline(UI::PictureComponent.new(src: SRC, alt: "A photo", width: 800, height: 600))

    assert_selector "picture img[width='800'][height='600']", visible: :all
  end
end
