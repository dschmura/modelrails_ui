# frozen_string_literal: true

require "render_test_helper"
load_component "avatar", "avatar_component.rb.tt"

class AvatarRenderTest < ViewComponent::TestCase
  def test_renders_an_image_avatar_when_src_is_given
    render_inline(UI::AvatarComponent.new(src: "https://example.com/a.png", aria_label: "Ada Lovelace"))

    assert_selector "img[src='https://example.com/a.png']"
  end

  # An image avatar exposed to AT carries its accessible name on alt (and role/aria-label).
  def test_image_avatar_has_a_meaningful_accessible_name
    render_inline(UI::AvatarComponent.new(src: "https://example.com/a.png", aria_label: "Ada Lovelace"))

    assert_selector "img[alt='Ada Lovelace']"
    assert_selector "img[aria-label='Ada Lovelace']"
  end

  def test_renders_an_initials_avatar_when_no_src
    render_inline(UI::AvatarComponent.new(fallback: "AL"))

    assert_selector "span", text: "AL"
  end

  # Initials are visible text, so a decorative avatar is aria-hidden by contract.
  def test_decorative_avatar_is_aria_hidden_and_not_focusable
    render_inline(UI::AvatarComponent.new(fallback: "AL"))

    assert_selector "span[aria-hidden='true']"
    assert_no_selector "span[tabindex]"
  end

  # Labeled initials avatar is announced as an image with its accessible name.
  def test_labeled_initials_avatar_is_announced
    render_inline(UI::AvatarComponent.new(fallback: "AL", aria_label: "Ada Lovelace"))

    assert_selector "span[role='img'][aria-label='Ada Lovelace']"
    assert_no_selector "span[aria-hidden]"
  end

  # AAA semantic tokens, not raw color: the default initials fill uses bg-interactive
  # with the adaptive on-color text-text-on-interactive (white in light, dark in dark).
  def test_default_initials_use_aaa_semantic_tokens
    render_inline(UI::AvatarComponent.new(fallback: "AL"))

    assert_selector "span.bg-interactive"
    assert_selector "span.text-text-on-interactive"
  end

  # The hue fill is the project's own semantic utility (fixed L=0.35, theme-independent),
  # engineered for AAA white text — that pairing is the documented correct one here.
  def test_hue_initials_use_the_semantic_hue_fill
    render_inline(UI::AvatarComponent.new(fallback: "AL", hue: 280))

    assert_selector "span.bg-hue-initials[style*='--hue: 280']"
  end

  def test_applies_the_requested_size
    render_inline(UI::AvatarComponent.new(fallback: "AL", size: :xl))

    assert_selector "span.w-32.h-32"
  end

  def test_merges_caller_classes
    render_inline(UI::AvatarComponent.new(fallback: "AL", class: "ring-2"))

    assert_selector "span.ring-2"
  end

  # Fail loud on an unknown size in dev/test (this harness is Rails-less, non-production).
  def test_raises_on_unknown_size
    error = assert_raises(ArgumentError) do
      render_inline(UI::AvatarComponent.new(fallback: "AL", size: :ginormous))
    end

    assert_match(/unknown size/, error.message)
  end
end
