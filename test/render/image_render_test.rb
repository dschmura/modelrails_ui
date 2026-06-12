# frozen_string_literal: true

require "render_test_helper"
load_component "image", "image_component.rb.tt"

class ImageRenderTest < ViewComponent::TestCase
  SRC = "https://example.com/photo.jpg"

  def test_renders_img_with_src_alt_and_lazy_loading
    render_inline(UI::ImageComponent.new(src: SRC, alt: "A photo"))

    assert_selector "img[src='#{SRC}'][alt='A photo'][loading='lazy']", visible: :all
  end

  def test_emits_responsive_and_dimension_attrs_only_when_given
    render_inline(UI::ImageComponent.new(
      src: SRC, alt: "A photo",
      srcset: "a.jpg 640w, b.jpg 1280w", sizes: "50vw",
      width: 800, height: 600
    ))

    assert_selector "img[srcset='a.jpg 640w, b.jpg 1280w'][sizes='50vw'][width='800'][height='600']", visible: :all
  end

  def test_omits_responsive_attrs_when_not_given
    render_inline(UI::ImageComponent.new(src: SRC, alt: "A photo"))

    assert_no_selector "img[srcset]", visible: :all
    assert_no_selector "img[sizes]", visible: :all
  end

  def test_omits_dimension_attrs_when_not_given
    render_inline(UI::ImageComponent.new(src: SRC, alt: "A photo"))

    assert_no_selector "img[width]", visible: :all
    assert_no_selector "img[height]", visible: :all
  end

  def test_invalid_loading_falls_back_to_lazy
    render_inline(UI::ImageComponent.new(src: SRC, alt: "A photo", loading: :bogus))

    assert_selector "img[loading='lazy']", visible: :all
  end

  # Empty alt is the correct decorative signal — it must render alt="".
  def test_decorative_empty_alt
    render_inline(UI::ImageComponent.new(src: SRC, alt: ""))

    assert_selector "img[alt='']", visible: :all
  end

  def test_merges_caller_classes
    render_inline(UI::ImageComponent.new(src: SRC, alt: "A photo", class: "rounded-lg"))

    assert_selector "img.rounded-lg", visible: :all
  end
end
