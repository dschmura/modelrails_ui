# frozen_string_literal: true

require "render_test_helper"
load_component "switch", "switch_component.rb.tt"

class SwitchRenderTest < ViewComponent::TestCase
  def test_renders_a_native_checkbox_with_switch_role
    render_inline(UI::SwitchComponent.new(name: "notifications"))

    assert_selector "input[type='checkbox'][role='switch']"
  end

  # The bug fix: a static aria-checked goes stale on toggle, so it must not exist
  # anywhere — the native checkbox `checked` conveys switch state under role=switch.
  def test_has_no_static_aria_checked_attribute
    render_inline(UI::SwitchComponent.new(name: "notifications", checked: true))

    assert_no_selector "[aria-checked]"
  end

  def test_checked_sets_native_checked_on_the_input
    render_inline(UI::SwitchComponent.new(name: "notifications", checked: true))

    assert_selector "input[type='checkbox'][role='switch'][checked]"
  end

  def test_unchecked_omits_native_checked
    render_inline(UI::SwitchComponent.new(name: "notifications"))

    assert_no_selector "input[checked]"
  end

  # The clickable track <label for> must point at the input id — clicking the
  # track toggles the control (association + click target).
  def test_track_label_is_associated_with_the_input
    render_inline(UI::SwitchComponent.new(id: "notify_switch"))

    assert_selector "input#notify_switch[type='checkbox']"
    assert_selector "label[for='notify_switch']"
  end

  # AAA 2.5.5 target size: the clickable track label carries a >=44px hit area.
  def test_clickable_track_label_meets_44px_target
    render_inline(UI::SwitchComponent.new(id: "notify_switch"))

    assert_selector "label.min-h-11.min-w-11"
  end

  def test_invalid_sets_aria_invalid_on_the_input
    render_inline(UI::SwitchComponent.new(name: "notifications", invalid: true))

    assert_selector "input[type='checkbox'][aria-invalid='true']"
  end

  def test_invalid_false_omits_aria_invalid
    render_inline(UI::SwitchComponent.new(name: "notifications"))

    assert_no_selector "input[aria-invalid]"
  end

  def test_describedby_sets_aria_describedby_on_the_input
    render_inline(UI::SwitchComponent.new(name: "notifications", describedby: "notify_hint"))

    assert_selector "input[type='checkbox'][aria-describedby='notify_hint']"
  end

  def test_describedby_absent_omits_aria_describedby
    render_inline(UI::SwitchComponent.new(name: "notifications"))

    assert_no_selector "input[aria-describedby]"
  end

  def test_id_falls_back_when_no_id_or_name_given
    render_inline(UI::SwitchComponent.new)

    assert_selector "input[type='checkbox'][role='switch']"
    assert_selector "label[for^='switch_']"
  end

  def test_renders_a_text_label_associated_with_the_input
    render_inline(UI::SwitchComponent.new(id: "notify_switch", label: "Email notifications"))

    assert_selector "label[for='notify_switch']", text: "Email notifications"
  end
end
