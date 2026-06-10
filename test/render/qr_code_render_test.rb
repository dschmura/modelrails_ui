# frozen_string_literal: true

require "render_test_helper"
load_component "qr_code", "qr_code_component.rb.tt"

# STRUCTURE-only render specs. A QR code is meaningful content, so the wrapper is a
# single labelled graphic (role="img" + aria-label) — that name covers BOTH the
# src: <img> path and the block (raw-SVG) path. The app 0b proves AAA in a browser;
# here we assert the accessible-name contract + semantic tokens + passthrough.
class QrCodeRenderTest < ViewComponent::TestCase
  def test_src_renders_an_img_inside_the_labelled_wrapper
    render_inline(UI::QrCodeComponent.new(src: "/qr.png", alt: "QR code linking to example.com"))

    assert_selector "div[role='img'][aria-label='QR code linking to example.com'] img", visible: :all
  end

  # The wrapper carries the accessible name; the inner <img> is decorative (alt="")
  # so AT announces the code once, not twice.
  def test_inner_img_is_decorative
    render_inline(UI::QrCodeComponent.new(src: "/qr.png", alt: "Scan me"))

    assert_selector "img[alt='']", visible: :all
    assert_selector "img[loading='lazy'][width='200'][height='200']", visible: :all
  end

  # The block (raw-SVG) path — the documented rqrcode usage — gets a real accessible
  # name from the wrapper, NOT a silent unlabelled <svg> (the broken behaviour).
  def test_block_svg_is_labelled_by_the_wrapper
    render_inline(UI::QrCodeComponent.new(alt: "QR code linking to example.com")) do
      "<svg viewBox='0 0 21 21'><path d='M0 0h21v21H0z'/></svg>".html_safe
    end

    assert_selector "div[role='img'][aria-label='QR code linking to example.com'] svg", visible: :all
  end

  # i18n default name when no alt is supplied (still a labelled graphic, never silent).
  def test_default_accessible_name_is_i18n_backed
    render_inline(UI::QrCodeComponent.new(src: "/qr.png"))

    assert_selector "div[role='img'][aria-label='QR code']", visible: :all
  end

  # Semantic AAA token — never raw `bg-white`.
  def test_uses_semantic_surface_token_not_raw_white
    render_inline(UI::QrCodeComponent.new(src: "/qr.png"))
    html = page.native.to_html

    assert_selector "div.bg-surface"
    refute_includes html, "bg-white"
  end

  # A caller-supplied class merges onto the wrapper without clobbering the base token.
  def test_merges_caller_class_onto_the_wrapper
    render_inline(UI::QrCodeComponent.new(src: "/qr.png", class: "mt-4"))

    assert_selector "div.mt-4.bg-surface"
  end

  # html_attrs pass through onto the wrapper <div>.
  def test_passes_through_html_attrs_onto_the_wrapper
    render_inline(UI::QrCodeComponent.new(src: "/qr.png", id: "checkout-qr", data: {testid: "qr"}))

    assert_selector "div#checkout-qr[data-testid='qr'][role='img']"
  end

  # Regression guard: a caller cannot strip the accessible name off the graphic.
  def test_caller_cannot_override_role_or_aria_label
    render_inline(UI::QrCodeComponent.new(src: "/qr.png", alt: "Scan me", role: "presentation", "aria-label": "x"))

    assert_selector "div[role='img'][aria-label='Scan me']"
    assert_no_selector "div[role='presentation']"
  end
end
