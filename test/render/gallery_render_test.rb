# frozen_string_literal: true

require "render_test_helper"
load_component "gallery", "gallery_component.rb.tt"

class GalleryRenderTest < ViewComponent::TestCase
  def gallery
    render_inline(UI::GalleryComponent.new(cols: 2)) do |g|
      g.with_image(src: "/a.jpg", alt: "Photo A")
      g.with_image(src: "/b.jpg", alt: "Photo B", caption: "The coast")
    end
  end

  def test_trigger_is_a_focusable_button_not_a_bare_figure
    gallery

    # WCAG 2.1.1: the lightbox opener must be keyboard-operable.
    assert_selector "button[type='button'][data-gallery-src-param='/a.jpg'][data-gallery-alt-param='Photo A']"
    # Each trigger carries an accessible name (the close button is asserted separately).
    assert_selector "button[data-gallery-src-param][aria-label]", count: 2
  end

  def test_trigger_wires_both_gallery_open_and_modal_open
    gallery

    assert_selector "button[data-action~='gallery#open'][data-action~='modal#open']", count: 2
  end

  def test_renders_one_reusable_dialog_with_modal_targets
    gallery

    assert_selector "dialog[data-modal-target='dialog']", count: 1
    assert_selector "dialog [data-modal-target='panel'] img[data-gallery-target='image']", count: 1, visible: :all
  end

  def test_lightbox_has_an_accessible_close_button
    gallery

    assert_selector "dialog button[data-action~='click->modal#close'][aria-label].focus-ring", visible: :all
  end

  def test_grid_wires_both_controllers
    gallery

    assert_selector "div[data-controller~='gallery'][data-controller~='modal']"
  end

  def test_caption_is_not_white_text_over_image
    gallery

    # Caption uses a semantic surface token, not text-white over a gradient.
    assert_no_selector "figcaption.text-white"
  end

  def test_lightbox_false_skips_dialog_and_renders_plain_images
    render_inline(UI::GalleryComponent.new(lightbox: false)) do |g|
      g.with_image(src: "/a.jpg", alt: "")
    end

    assert_no_selector "dialog"
    assert_no_selector "button"
    assert_selector "img[src='/a.jpg']"
  end

  def test_alt_required_when_lightbox_enabled
    error = assert_raises(ArgumentError) do
      render_inline(UI::GalleryComponent.new) { |g| g.with_image(src: "/a.jpg", alt: "") }
    end

    assert_match(/alt/, error.message)
  end
end
