# frozen_string_literal: true

require "render_test_helper"
load_component "floating_label", "floating_label_component.rb.tt"

class FloatingLabelRenderTest < ViewComponent::TestCase
  def test_renders_div_wrapping_a_peer_input
    render_inline(UI::FloatingLabelComponent.new(label: "Email"))

    assert_selector "div.relative input.peer"
  end

  # AAA semantic tokens (the design-token guarantee), not raw Tailwind:
  def test_renders_with_aaa_tokens
    render_inline(UI::FloatingLabelComponent.new(label: "Email"))

    assert_selector "input.border-border-strong"
    assert_selector "input.focus-visible\\:ring-interactive-focus"
  end

  def test_label_text_renders
    render_inline(UI::FloatingLabelComponent.new(label: "Email address"))

    assert_selector "label", text: "Email address"
  end

  # The peer-float mechanism: the label must be a LATER SIBLING of the input
  # so `peer-focus:` / `peer-[:not(:placeholder-shown)]:` selectors match.
  def test_label_is_rendered_after_the_input_as_a_sibling
    render_inline(UI::FloatingLabelComponent.new(label: "Email"))

    # input + label adjacency: a label immediately following the peer input.
    assert_selector "div.relative input.peer + label"
  end

  # Label association: the <label for=...> targets the input's id.
  def test_label_is_associated_via_for_matching_input_id
    render_inline(UI::FloatingLabelComponent.new(label: "Email", name: "user[email]"))

    input_id = page.find("input.peer")[:id]

    refute_nil input_id, "input must carry an id so the label can associate"
    assert_selector "label[for='#{input_id}']", text: "Email"
  end

  # Fallback id: with NEITHER id nor name, the input STILL has an id and the
  # label's `for` matches it (so the control is always labelled).
  def test_label_associates_even_without_id_or_name
    render_inline(UI::FloatingLabelComponent.new(label: "Email"))

    input_id = page.find("input.peer")[:id]

    refute_nil input_id, "input must carry a fallback id even without id/name"
    refute_empty input_id.to_s
    assert_selector "label[for='#{input_id}']", text: "Email"
  end

  # invalid: drives the server-validation-driven aria-invalid posture and
  # activates the existing `aria-invalid:` style hooks.
  def test_invalid_sets_aria_invalid
    render_inline(UI::FloatingLabelComponent.new(label: "Email", invalid: true))

    assert_selector "input.peer[aria-invalid='true']"
  end

  def test_not_invalid_by_default
    render_inline(UI::FloatingLabelComponent.new(label: "Email"))

    assert_no_selector "input[aria-invalid]"
  end

  def test_required_sets_required_and_aria_required
    render_inline(UI::FloatingLabelComponent.new(label: "Email", required: true))

    assert_selector "input.peer[required][aria-required='true']"
  end

  def test_not_required_by_default
    render_inline(UI::FloatingLabelComponent.new(label: "Email"))

    assert_no_selector "input[required]"
    assert_no_selector "input[aria-required]"
  end

  def test_describedby_sets_aria_describedby
    render_inline(UI::FloatingLabelComponent.new(label: "Email", describedby: "email_error"))

    assert_selector "input.peer[aria-describedby='email_error']"
  end

  def test_no_describedby_omits_the_attribute
    render_inline(UI::FloatingLabelComponent.new(label: "Email"))

    assert_no_selector "input[aria-describedby]"
  end
end
