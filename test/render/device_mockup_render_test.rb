# frozen_string_literal: true

require "render_test_helper"
load_component "device_mockup", "device_mockup_component.rb.tt"

class DeviceMockupRenderTest < ViewComponent::TestCase
  def test_phone_frame_wraps_slotted_content
    render_inline(UI::DeviceMockupComponent.new(variant: :phone)) { "<p>Screenshot</p>".html_safe }

    assert_selector "div", text: "Screenshot"
  end

  def test_browser_frame_wraps_slotted_content
    render_inline(UI::DeviceMockupComponent.new(variant: :browser)) { "<p>Dashboard</p>".html_safe }

    assert_selector "div", text: "Dashboard"
  end

  # The notch is decorative chrome — AT must not perceive it.
  def test_phone_notch_chrome_is_aria_hidden
    render_inline(UI::DeviceMockupComponent.new(variant: :phone))

    assert_selector "div[aria-hidden='true']"
  end

  # The browser bar (traffic-light dots + fake address bar) is decorative chrome:
  # the whole bar is aria-hidden so the cosmetic URL is never announced.
  def test_browser_bar_chrome_is_aria_hidden
    render_inline(UI::DeviceMockupComponent.new(variant: :browser, url: "https://example.com")) { "x" }

    assert_selector "div[aria-hidden='true']", text: "https://example.com"
  end

  # The mockup wrapper is a plain <div> — no bogus role; only the slotted
  # content carries semantics.
  def test_wrapper_has_no_bogus_role
    render_inline(UI::DeviceMockupComponent.new(variant: :phone)) { "y" }

    assert_no_selector "div[role]"
  end

  # AAA semantic tokens, never raw palette colors (no bg-white, no bg-red-400).
  def test_renders_with_aaa_semantic_tokens
    render_inline(UI::DeviceMockupComponent.new(variant: :browser)) { "z" }

    assert_selector "div.bg-surface-sunken"
    assert_selector "div.border-border"
    assert_no_selector "div.bg-white"
  end

  def test_merges_caller_classes
    render_inline(UI::DeviceMockupComponent.new(variant: :phone, class: "my-8")) { "c" }

    assert_selector "div.my-8"
  end

  # Fail loud on an unknown variant so misuse is caught immediately in dev/test.
  def test_raises_on_unknown_variant
    assert_raises(ArgumentError) do
      render_inline(UI::DeviceMockupComponent.new(variant: :watch))
    end
  end
end
