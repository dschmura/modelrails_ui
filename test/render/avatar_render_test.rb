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

  # The hue fill is the project's own semantic utility, theme-aware since #144: the
  # lightness comes from --hue-initials-l, which .dark re-lights, and the on-color rides
  # along in its own token. The pairing is asserted because the bug was a hardcoded
  # text-white that could not follow the fill.
  def test_hue_initials_use_the_semantic_hue_fill_with_its_adaptive_on_color
    render_inline(UI::AvatarComponent.new(fallback: "AL", hue: 280))

    assert_selector "span.bg-hue-initials.text-text-on-hue-initials[style*='--hue: 280']"
    refute_selector "span.bg-hue-initials.text-white"
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

  # `fallback:` alone only ever covered a NIL src; a 404 still left a broken-image glyph.
  # The recovery pair is rendered only when BOTH a src and a fallback exist, so a
  # src-only call site keeps its bare <img>.
  def test_src_without_fallback_stays_a_bare_img
    render_inline(UI::AvatarComponent.new(src: "/a.png", aria_label: "Dave"))

    assert_no_selector "[data-controller~='avatar']", visible: :all
  end

  def test_src_with_fallback_wires_the_error_handler
    render_inline(UI::AvatarComponent.new(src: "/a.png", fallback: "DC", aria_label: "Dave"))

    assert_selector "[data-controller~='avatar'] img[data-action~='error->avatar#showFallback']", visible: :all
  end

  def test_standby_initials_ship_hidden
    render_inline(UI::AvatarComponent.new(src: "/a.png", fallback: "DC", aria_label: "Dave"))

    assert_selector "[data-avatar-target='fallback'][hidden]", text: "DC", visible: :all
  end

  # BOTH nodes are named: the <img> is REMOVED on failure and carries the name, so
  # unnamed initials would leave the avatar absent from the accessibility tree entirely.
  # `hidden` keeps only one of them exposed at a time.
  def test_standby_initials_are_named_for_after_the_swap
    render_inline(UI::AvatarComponent.new(src: "/a.png", fallback: "DC", aria_label: "Dave"))

    assert_selector "[data-avatar-target='fallback'][role='img'][aria-label='Dave']", visible: :all
  end

  # The recovered initials must render in the CALLER's hue: the standby span carries
  # the same --hue custom property the initials branch renders, or a 404'd logo for a
  # custom-color identity silently recovers in the default hue.
  def test_standby_initials_keep_the_callers_hue
    render_inline(UI::AvatarComponent.new(src: "/a.png", fallback: "DC", hue: 280))

    assert_selector "[data-avatar-target='fallback'].bg-hue-initials[style*='--hue: 280']", visible: :all
  end

  def test_avatar_is_named_once_among_visible_nodes
    render_inline(UI::AvatarComponent.new(src: "/a.png", fallback: "DC", aria_label: "Dave"))

    assert_selector "[aria-label='Dave']", count: 1
  end

  # A caller `data:` used to splat over the wiring and silently disable the fallback —
  # the component rendered, looked right, and never recovered from a 404.
  def test_caller_data_does_not_clobber_the_error_wiring
    render_inline(UI::AvatarComponent.new(src: "/a.png", fallback: "DC", aria_label: "Dave",
      data: {testid: "user-avatar"}))

    assert_selector "img[data-action~='error->avatar#showFallback'][data-testid='user-avatar']", visible: :all
  end
end
