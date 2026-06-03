# frozen_string_literal: true

require "render_test_helper"
load_component "label", "label_component.rb.tt"

class LabelRenderTest < ViewComponent::TestCase
  def test_renders_a_label_with_text
    render_inline(UI::LabelComponent.new("Email address"))

    assert_selector "label", text: "Email address"
  end

  # A label is NOT an input: it carries no invalid/aria-invalid/describedby.
  def test_is_not_an_input
    render_inline(UI::LabelComponent.new("Email address"))

    assert_no_selector "label[aria-invalid]"
    assert_no_selector "label[aria-describedby]"
  end

  # AAA semantic token (the design-token guarantee), not a raw Tailwind color:
  # text-text-body meets the 7:1 floor on the surface.
  def test_renders_with_aaa_token
    render_inline(UI::LabelComponent.new("Email address"))

    assert_selector "label.text-text-body"
  end

  # Association: for: targets the input's id so clicking the label focuses it.
  def test_for_associates_to_an_input_id
    render_inline(UI::LabelComponent.new("Email address", for: "user_email"))

    assert_selector "label[for='user_email']", text: "Email address"
  end

  def test_no_for_attribute_when_unset
    render_inline(UI::LabelComponent.new("Email address"))

    assert_no_selector "label[for]"
  end

  # required: renders a decorative asterisk. The marker is aria-hidden — the
  # actual requirement is conveyed on the input (aria-required), never the label.
  def test_required_renders_decorative_asterisk
    render_inline(UI::LabelComponent.new("Email address", required: true))

    assert_selector "label span[aria-hidden='true']", text: "*"
  end

  def test_not_required_by_default
    render_inline(UI::LabelComponent.new("Email address"))

    assert_no_selector "label span[aria-hidden='true']"
  end

  # The visible label text is still present alongside the required marker.
  def test_required_keeps_the_label_text
    render_inline(UI::LabelComponent.new("Email address", required: true))

    assert_selector "label", text: "Email address"
  end

  # Block content takes precedence over the text arg (the wrapping pattern).
  def test_block_content_renders
    render_inline(UI::LabelComponent.new(for: "user_name")) { "Full name" }

    assert_selector "label[for='user_name']", text: "Full name"
  end
end
