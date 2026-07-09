# frozen_string_literal: true

require "test_helper"
require "modelrails_ui/adoption/usage"
require "modelrails_ui/adoption/adapter_map"

class TestAdoptionUsage < Minitest::Test
  APP = File.expand_path("fixtures/adoption_app", __dir__)
  PARTIAL_APP = File.expand_path("fixtures/adoption_app_partial_dialog", __dir__)

  def usage
    @usage ||= ModelrailsUi::Adoption::Usage.new(
      app_root: APP, adapter_map: ModelrailsUi::Adoption::AdapterMap::DEFAULTS
    )
  end

  def partial_usage
    @partial_usage ||= ModelrailsUi::Adoption::Usage.new(
      app_root: PARTIAL_APP, adapter_map: ModelrailsUi::Adoption::AdapterMap::DEFAULTS
    )
  end

  def test_direct_ui_call_space_and_paren_forms
    assert_equal :direct, usage.classify("alert")[:value]
    assert_equal :direct, usage.classify("badge")[:value]
  end

  def test_render_constant_form_is_direct
    assert_equal :direct, usage.classify("dialog")[:value] # note: dialog is ALSO an adapter; direct host call wins
  end

  def test_button_via_utility_class_is_never_dead
    result = usage.classify("button")

    assert_equal :utility_standin, result[:value]
    assert_match(/btn-/, result[:detail])
  end

  def test_comment_only_reference_is_not_adopted
    assert_equal :none, usage.classify("qr_code")[:value]
  end

  def test_composition_only_inside_components_is_transitive
    assert_equal :transitive, usage.classify("card_title")[:value]
  end

  def test_dynamic_invocation_is_unknown_not_dead
    assert_equal :unknown, usage.classify("input")[:value] # input appears only via dynamic ui(name) here... see note
  end

  def test_genuinely_absent_component_is_none
    assert_equal :none, usage.classify("carousel")[:value]
  end

  def test_inflection_edge_names_resolve
    # input_otp → InputOtpComponent, qr_code → QrCodeComponent must not error
    assert_kind_of Hash, usage.classify("input_otp")
    assert_kind_of Hash, usage.classify("qr_code")
  end

  def test_method_adapter_is_reachable_via_form_builder_call
    result = usage.classify("textarea") # f.text_area :bio, no `ui :textarea` anywhere

    assert_equal :adapter, result[:value]
    assert_match(/text_area/, result[:detail])
  end

  def test_helper_adapter_is_reachable_via_helper_call
    result = usage.classify("avatar") # avatar_for(@user), no `ui :avatar` anywhere

    assert_equal :adapter, result[:value]
    assert_match(/avatar_for/, result[:detail])
  end

  def test_direct_beats_a_genuinely_present_adapter
    # file_input has BOTH `ui :file_input` and `f.file_field :doc` in the fixture —
    # direct must win over adapter, proving precedence isn't an artifact of the
    # adapter simply never being reachable.
    assert_equal :direct, usage.classify("file_input")[:value]
  end

  def test_string_literal_reference_does_not_inflate_adoption
    # `data-hint="ui :carousel"` is a quoted HTML attribute, not real code.
    # Without string-stripping in the `code` variant this would false-match
    # direct? and misclassify carousel as :direct instead of :none.
    assert_equal :none, usage.classify("carousel")[:value]
  end

  def test_partial_adapter_is_reachable_via_rendered_partial_only
    # dialog's adapter is {kind: :partial, value: "shared/_modal"}. In this
    # fixture app dialog is reached ONLY via a rendered partial
    # (`render "shared/modal"`) — no direct `render UI::DialogComponent`
    # anywhere. A partial path only ever appears inside a quoted render
    # argument, so adapter_hit?'s :partial branch must scan the
    # strings-PRESERVED `markup` variant. Scanning the strings-stripped
    # `code` variant (the bug) blanks that argument to `""` and the branch
    # can never match, so this fixture would misclassify as :none.
    result = partial_usage.classify("dialog")

    assert_equal :adapter, result[:value]
    assert_match(/shared\/_modal/, result[:detail])
  end
end
