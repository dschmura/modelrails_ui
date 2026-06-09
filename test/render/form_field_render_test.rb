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

  def test_error_has_an_id_alert_role_and_description_slot
    render_field(error: "is required")

    assert_selector "p#user_email-error[role='alert'][data-slot='description']", text: "is required"
  end

  def test_label_carries_the_data_slot_for_adjacency_spacing
    render_field

    assert_selector "label[data-slot='label']"
  end

  def test_input_attrs_expose_the_full_wiring
    c = UI::FormFieldComponent.new(id: "user_email", label: "Email", hint: "h", error: "e", required: true)

    assert_equal(
      {id: "user_email", describedby: "user_email-hint user_email-error", invalid: true, required: true},
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
end
