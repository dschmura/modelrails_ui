# frozen_string_literal: true

require "render_test_helper"
load_component "input_otp", "input_otp_component.rb.tt"

# STRUCTURE-only render specs. input_otp is a labelled role="group" of N numeric
# single-character cells wired to the input-otp Stimulus controller. The app 0b
# proves AAA + the live auto-advance/paste behavior in a real browser; here we
# assert the scaffolding, the group/per-digit accessible names, the focus-ring
# contract, and the numeric/one-time-code input hints.
class InputOtpRenderTest < ViewComponent::TestCase
  def test_renders_n_cells_wired_to_the_controller_without_error
    render_inline(UI::InputOtpComponent.new(length: 6, name: "otp"))

    assert_selector "div[data-controller='input-otp']"
    assert_selector "input[data-input-otp-target='cell']", count: 6
  end

  def test_cells_post_under_the_indexed_field_name
    render_inline(UI::InputOtpComponent.new(length: 6, name: "otp"))

    assert_selector "input[name='otp[0]']"
    assert_selector "input[name='otp[5]']"
  end

  def test_default_length_is_six
    render_inline(UI::InputOtpComponent.new)

    assert_selector "input[data-input-otp-target='cell']", count: 6
  end

  # The group landmark gets an accessible name (i18n default) so a screen-reader
  # user knows the row of fields is an OTP entry.
  def test_group_has_role_and_i18n_default_accessible_name
    render_inline(UI::InputOtpComponent.new(length: 4))

    assert_selector "div[role='group'][aria-label='One-time passcode']"
  end

  def test_custom_label_names_the_group
    render_inline(UI::InputOtpComponent.new(length: 4, label: "Verification code"))

    assert_selector "div[role='group'][aria-label='Verification code']"
  end

  # Each cell carries a per-digit label announcing its position in the sequence.
  def test_each_cell_has_a_per_digit_label_with_position_and_total
    render_inline(UI::InputOtpComponent.new(length: 6))

    assert_selector "input[aria-label='Digit 1 of 6']"
    assert_selector "input[aria-label='Digit 6 of 6']"
  end

  # The cells carry the AAA offset focus-ring (not a box-shadow ring).
  def test_cells_carry_the_focus_ring
    render_inline(UI::InputOtpComponent.new(length: 3))

    assert_selector "input.focus-ring[data-input-otp-target='cell']", count: 3
  end

  # Regression guard: the ring/outline-none anti-pattern must never come back.
  def test_no_box_shadow_ring_or_outline_none
    render_inline(UI::InputOtpComponent.new(length: 3))
    html = page.native.to_html

    refute_includes html, "focus-visible:ring-"
    refute_includes html, "focus:ring-"
    refute_includes html, "outline-none"
  end

  # Numeric keypad on mobile + OS/browser one-time-code autofill on every cell.
  def test_cells_are_numeric_and_one_time_code
    render_inline(UI::InputOtpComponent.new(length: 6))

    assert_selector "input[inputmode='numeric']", count: 6
    assert_selector "input[autocomplete='one-time-code']", count: 6
    assert_selector "input[maxlength='1']", count: 6
  end

  # The cells wire input/keydown/paste to the controller (auto-advance + paste).
  def test_cells_wire_input_keydown_and_paste_actions
    render_inline(UI::InputOtpComponent.new(length: 2))

    assert_selector "input[data-action~='input->input-otp#onInput']", count: 2
    assert_selector "input[data-action~='keydown->input-otp#onKeydown']", count: 2
    assert_selector "input[data-action~='paste->input-otp#onPaste']", count: 2
  end

  # Integer separator inserts a decorative span between cells without adding a cell.
  def test_integer_separator_inserts_a_decorative_span
    render_inline(UI::InputOtpComponent.new(length: 6, separator: 3))

    assert_selector "input[data-input-otp-target='cell']", count: 6
    assert_selector "span[aria-hidden='true']", text: "-"
  end

  def test_hash_separator_uses_the_supplied_char
    render_inline(UI::InputOtpComponent.new(length: 4, separator: {2 => "·"}))

    assert_selector "span[aria-hidden='true']", text: "·"
  end

  # Fail loud: a non-positive length is a programming error, not a state.
  def test_non_positive_length_raises
    assert_raises(ArgumentError) { UI::InputOtpComponent.new(length: 0) }
    assert_raises(ArgumentError) { UI::InputOtpComponent.new(length: -3) }
  end

  # html_attrs pass through onto the group root, and a caller can't clobber the
  # role or accessible name (the component's a11y contract wins).
  def test_passes_through_html_attrs_onto_the_root
    render_inline(UI::InputOtpComponent.new(length: 4, id: "otp-group", data: {testid: "otp"}))

    assert_selector "div#otp-group[data-testid='otp'][data-controller='input-otp']"
  end

  def test_caller_cannot_clobber_the_group_role_or_label
    render_inline(UI::InputOtpComponent.new(length: 4, role: "presentation", "aria-label": "Hijacked"))

    assert_selector "div[role='group'][aria-label='One-time passcode']"
    assert_no_selector "div[role='presentation']"
  end

  # A caller-supplied class merges onto the root without clobbering the layout.
  def test_merges_caller_class_onto_the_root
    render_inline(UI::InputOtpComponent.new(length: 4, class: "mt-4"))

    assert_selector "div.mt-4.flex.items-center"
  end
end
