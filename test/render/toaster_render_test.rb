# frozen_string_literal: true

require "render_test_helper"
load_component "toaster", "toaster_component.rb.tt"

class ToasterRenderTest < ViewComponent::TestCase
  # --- The stack container is a polite live region landmark ---

  def test_container_is_a_polite_live_region_with_an_i18n_name
    render_inline(UI::ToasterComponent.new)

    assert_selector "div[role='status'][aria-live='polite'][aria-label='Notifications']"
  end

  def test_container_wires_the_toaster_controller
    render_inline(UI::ToasterComponent.new)

    assert_selector "div[data-controller='toaster'][data-action='toaster:add@window->toaster#add']"
  end

  def test_container_anchors_to_the_requested_position
    render_inline(UI::ToasterComponent.new(position: :top_center))

    assert_selector "div.fixed.top-4"
  end

  def test_renders_toasts_passed_through_the_slot
    render_inline(UI::ToasterComponent.new) do |t|
      t.with_toast(message: "Profile saved", severity: :success)
    end

    assert_selector "div[role='status'] [data-toaster-target='toast']", text: "Profile saved"
  end

  # --- Per-toast severity uses tinted signal tokens, never raw palette ---

  def test_default_toast_uses_aaa_neutral_tokens
    render_inline(UI::ToasterComponent::ToastComponent.new(message: "Hi"))

    assert_selector "div.bg-surface-raised.border-border.text-text-body", text: "Hi"
    # A default toast announces politely.
    assert_selector "div[role='status'][aria-live='polite']"
  end

  def test_success_toast_uses_tinted_success_surface_not_raw_palette
    render_inline(UI::ToasterComponent::ToastComponent.new(message: "Saved", severity: :success))

    assert_selector "div.bg-success-surface.border-success-border.text-success"
    # Regression guard: the old raw-palette treatment is gone.
    assert_no_selector "[class*='green-500']"
  end

  def test_warning_toast_uses_tinted_warning_surface_not_raw_palette
    render_inline(UI::ToasterComponent::ToastComponent.new(message: "Heads up", severity: :warning))

    assert_selector "div.bg-warning-surface.border-warning-border.text-warning"
    assert_no_selector "[class*='amber-500']"
  end

  def test_info_toast_uses_tinted_info_surface_not_raw_palette
    render_inline(UI::ToasterComponent::ToastComponent.new(message: "FYI", severity: :info))

    assert_selector "div.bg-info-surface.border-info-border.text-info"
    assert_no_selector "[class*='blue-500']"
  end

  # --- danger is the only urgent toast: an assertive alert on the danger surface ---

  def test_danger_toast_is_an_assertive_alert_on_the_danger_surface
    render_inline(UI::ToasterComponent::ToastComponent.new(message: "Couldn't save", severity: :danger))

    assert_selector "div[role='alert'][aria-live='assertive'].bg-danger-surface", text: "Couldn't save"
    # No opacity hack on the signal text token (would drop below the AAA 7:1 floor).
    assert_no_selector "[class*='text-danger/']"
  end

  # --- Severity aliases (legacy gem + app flash-pipeline names) ---

  # `destructive` is the legacy gem name for the canonical `danger`.
  def test_destructive_alias_renders_identically_to_danger
    render_inline(UI::ToasterComponent::ToastComponent.new(message: "x", severity: :destructive))

    assert_selector "div[role='alert'][aria-live='assertive'].bg-danger-surface"
  end

  # The app `shared/_toasts` flash names collide with the signal axis: there `:alert`
  # reads as a warning and `:error` as danger. Both are accepted as aliases.
  def test_flash_alert_alias_maps_to_warning
    render_inline(UI::ToasterComponent::ToastComponent.new(message: "x", severity: :alert))

    assert_selector "div[role='status'].bg-warning-surface"
  end

  def test_flash_error_alias_maps_to_danger
    render_inline(UI::ToasterComponent::ToastComponent.new(message: "x", severity: :error))

    assert_selector "div[role='alert'][aria-live='assertive'].bg-danger-surface"
  end

  # The deprecated `variant:` keyword is still accepted as an alias for `severity:`.
  def test_deprecated_variant_keyword_still_resolves
    render_inline(UI::ToasterComponent::ToastComponent.new(message: "x", variant: :success))

    assert_selector "div.bg-success-surface"
  end

  # --- The dismiss control: named, focus-ring, 44px target ---

  def test_dismiss_button_is_named_and_uses_the_focus_ring_utility
    render_inline(UI::ToasterComponent::ToastComponent.new(message: "Hi"))

    assert_selector "button[type='button'][aria-label='Dismiss'].focus-ring"
  end

  def test_dismiss_button_meets_the_44px_target
    render_inline(UI::ToasterComponent::ToastComponent.new(message: "Hi"))

    # size-11 = 2.75rem = 44px (the AAA 2.5.5 minimum target size).
    assert_selector "button[aria-label='Dismiss'].size-11"
  end

  def test_dismiss_button_never_uses_a_clipped_box_shadow_ring
    render_inline(UI::ToasterComponent::ToastComponent.new(message: "Hi"))

    assert_no_selector "button[class*='focus-visible:ring']"
  end

  # --- Title + message body ---

  def test_renders_an_optional_bold_title_above_the_message
    render_inline(UI::ToasterComponent::ToastComponent.new(title: "Saved", message: "All changes stored"))

    assert_selector "p.font-semibold", text: "Saved"
    assert_selector "p", text: "All changes stored"
  end

  # --- Fail loud ---

  def test_unknown_severity_raises
    error = assert_raises(ArgumentError) do
      render_inline(UI::ToasterComponent::ToastComponent.new(message: "x", severity: :bogus))
    end

    assert_match(/unknown severity/, error.message)
  end

  # --- html_attrs / class passthrough on both the container and the toast ---

  def test_container_passes_through_html_attrs
    render_inline(UI::ToasterComponent.new(id: "toast-stack", data: {testid: "toaster"}))

    assert_selector "div#toast-stack[data-testid='toaster']"
  end

  def test_toast_passes_through_html_attrs
    render_inline(UI::ToasterComponent::ToastComponent.new(message: "x", id: "t1", data: {testid: "toast"}))

    assert_selector "div#t1[data-testid='toast']"
  end

  def test_merges_caller_class_without_clobbering_severity_tokens
    render_inline(UI::ToasterComponent::ToastComponent.new(message: "x", severity: :success, class: "mb-4"))

    assert_selector "div.mb-4.bg-success-surface"
  end
end
