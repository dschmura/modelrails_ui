# frozen_string_literal: true

require "render_test_helper"
# FormFieldComponent renders the Label primitive, so both must be loaded.
load_component "label", "label_component.rb.tt"
load_component "form_field", "form_field_component.rb.tt"

class FormFieldRenderTest < ViewComponent::TestCase
  def render_field(**opts)
    render_inline(UI::FormFieldComponent.new(id: "user_email", label: "Email", **opts)) do
      "CONTROL"
    end
  end

  def test_label_is_bound_to_the_control_with_for
    render_field

    assert_selector "label[for='user_email']", text: "Email"
  end

  def test_control_is_wrapped_in_a_data_slot_control_group
    render_field

    assert_selector "[data-slot='control']", text: "CONTROL"
  end

  def test_hint_has_an_id_and_description_slot
    render_field(hint: "No spam.")

    assert_selector "p#user_email-hint[data-slot='description']", text: "No spam."
  end

  def test_error_is_a_plain_paragraph_with_id_and_description_slot
    render_field(error: "is required")

    assert_selector "p#user_email-error[data-slot='description']", text: "is required"
    # No live region on the server-rendered path: the focused ErrorSummary is the
    # announcement mechanism; role=alert here never fires (region arrives with content).
    assert_no_selector "p#user_email-error[role='alert']"
  end

  def test_label_carries_the_data_slot_for_adjacency_spacing
    render_field

    assert_selector "label[data-slot='label']"
  end

  def test_input_attrs_expose_the_full_wiring
    c = UI::FormFieldComponent.new(id: "user_email", label: "Email", hint: "h", error: "e", required: true)

    assert_equal(
      {id: "user_email", describedby: "user_email-error user_email-hint", invalid: true, required: true},
      c.input_attrs
    )
  end

  def test_input_attrs_describedby_is_nil_with_no_hint_or_error
    c = UI::FormFieldComponent.new(id: "user_email", label: "Email")

    assert_nil c.input_attrs[:describedby]
    refute c.input_attrs[:invalid]
  end

  def test_required_marker_is_decorative_on_the_label
    render_field(required: true)

    assert_selector "label span[aria-hidden='true']", text: "*"
  end

  def test_describedby_is_error_first_then_hint
    c = UI::FormFieldComponent.new(id: "f", hint: "h", error: "e")

    assert_equal "f-error f-hint", c.input_attrs[:describedby]
  end

  def test_html_input_attrs_translate_to_real_aria_attributes
    c = UI::FormFieldComponent.new(id: "f", hint: "h", error: "e", required: true)

    assert_equal(
      {:id => "f", "aria-describedby" => "f-error f-hint", "aria-invalid" => "true", "aria-required" => "true"},
      c.html_input_attrs
    )
  end

  def test_html_input_attrs_omit_absent_axes
    c = UI::FormFieldComponent.new(id: "f")

    assert_equal({id: "f"}, c.html_input_attrs)
  end

  def test_hint_and_error_classes_are_public_shared_constants
    assert_equal "text-sm text-text-muted", UI::FormFieldComponent::HINT_CLASSES
    assert_equal "text-sm text-danger", UI::FormFieldComponent::ERROR_CLASSES
  end

  def test_fallback_id_is_derived_from_the_label_and_stable_across_instances
    first = UI::FormFieldComponent.new(label: "Email address")
    second = UI::FormFieldComponent.new(label: "Email address")

    assert_equal "form_field_email_address", first.input_attrs[:id]
    assert_equal first.input_attrs[:id], second.input_attrs[:id]
  end

  def test_fallback_id_with_no_label_and_no_id_is_the_constant_fallback
    c = UI::FormFieldComponent.new

    assert_equal "form_field", c.input_attrs[:id]
  end

  def test_explicit_id_wins_over_the_label_derived_fallback
    c = UI::FormFieldComponent.new(id: "custom_id", label: "Email address")

    assert_equal "custom_id", c.input_attrs[:id]
  end
end
