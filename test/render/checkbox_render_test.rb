# frozen_string_literal: true

require "render_test_helper"
load_component "checkbox", "checkbox_component.rb.tt"

class CheckboxRenderTest < ViewComponent::TestCase
  def test_renders_a_checkbox_input
    render_inline(UI::CheckboxComponent.new(label: "Accept terms", name: "terms"))

    assert_selector "input[type='checkbox']"
  end

  # AAA semantic tokens (the design-token guarantee), not raw Tailwind:
  def test_renders_with_aaa_tokens
    render_inline(UI::CheckboxComponent.new(label: "Accept terms", name: "terms"))

    assert_selector "input.border-border-strong"
    assert_selector "input.focus-ring"
    assert_selector "input.checked\\:bg-interactive"
  end

  # Label association: the <label for=...> targets the input's id.
  def test_label_is_associated_via_for_matching_input_id
    render_inline(UI::CheckboxComponent.new(label: "Accept terms", name: "terms"))

    input_id = page.find("input[type='checkbox']")[:id]

    refute_nil input_id, "input must carry an id so the label can associate"
    assert_selector "label[for='#{input_id}']", text: "Accept terms"
  end

  # Fallback id: with NEITHER id nor name, the input STILL has an id and the
  # label's `for` matches it (so the control is always labelled).
  def test_label_associates_even_without_id_or_name
    render_inline(UI::CheckboxComponent.new(label: "Accept terms"))

    input_id = page.find("input[type='checkbox']")[:id]

    refute_nil input_id, "input must carry a fallback id even without id/name"
    refute_empty input_id.to_s
    assert_selector "label[for='#{input_id}']", text: "Accept terms"
  end

  def test_checked_sets_the_checked_attribute
    render_inline(UI::CheckboxComponent.new(label: "Accept terms", name: "terms", checked: true))

    assert_selector "input[type='checkbox'][checked]"
  end

  # invalid: drives the server-validation-driven aria-invalid posture.
  def test_invalid_sets_aria_invalid
    render_inline(UI::CheckboxComponent.new(label: "Accept terms", name: "terms", invalid: true))

    assert_selector "input[type='checkbox'][aria-invalid='true']"
  end

  def test_not_invalid_by_default
    render_inline(UI::CheckboxComponent.new(label: "Accept terms", name: "terms"))

    assert_no_selector "input[aria-invalid='true']"
  end

  def test_describedby_sets_aria_describedby
    render_inline(UI::CheckboxComponent.new(label: "Accept terms", name: "terms", describedby: "terms_error"))

    assert_selector "input[type='checkbox'][aria-describedby='terms_error']"
  end
end
