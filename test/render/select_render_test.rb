# frozen_string_literal: true

require "render_test_helper"
load_component "select", "select_component.rb.tt"

class SelectRenderTest < ViewComponent::TestCase
  def test_renders_native_select_with_options
    render_inline(UI::SelectComponent.new(options: %w[Draft Published]))

    assert_selector "select"
    assert_selector "select option", text: "Draft"
    assert_selector "select option", text: "Published"
  end

  # --- optgroups (#162) ------------------------------------------------------
  #
  # A Hash whose VALUES are Arrays is read as groups; a Hash of scalars stays the
  # flat `{ value => label }` shape. That disambiguation is what makes the feature
  # backward compatible, so both halves are asserted.
  #
  # Pairs stay `[value, label]`, matching this component's own flat array shape.
  # Rails' `grouped_options_for_select` uses `[label, value]`; consistency inside
  # the component wins, because a caller adding groups should not have to flip
  # pairs they already wrote.

  def render_grouped
    render_inline(UI::SelectComponent.new(options: {
      "Americas" => [["us", "United States"], ["ca", "Canada"]],
      "Europe" => [["fr", "France"]]
    }))
  end

  def test_grouped_options_render_one_optgroup_per_key
    render_grouped

    assert_selector "select optgroup", count: 2
    assert_selector "select optgroup[label='Americas']"
    assert_selector "select optgroup[label='Europe']"
  end

  def test_grouped_options_nest_their_members
    render_grouped

    assert_selector "optgroup[label='Americas'] option[value='us']", text: "United States"
    assert_selector "optgroup[label='Americas'] option[value='ca']", text: "Canada"
    assert_selector "optgroup[label='Europe'] option[value='fr']", text: "France"
  end

  def test_a_flat_hash_is_still_flat_options
    render_inline(UI::SelectComponent.new(options: {draft: "Draft", published: "Published"}))

    assert_no_selector "select optgroup"
    assert_selector "select > option[value='draft']", text: "Draft"
  end

  def test_selected_marks_an_option_inside_a_group
    render_inline(UI::SelectComponent.new(
      options: {"Americas" => [["us", "United States"], ["ca", "Canada"]]}, selected: "ca"
    ))

    assert_selector "optgroup option[value='ca'][selected]"
    assert_no_selector "optgroup option[value='us'][selected]"
  end

  # A group's members take the same shorthand as the flat shape.
  def test_bare_strings_inside_a_group_become_value_and_label
    render_inline(UI::SelectComponent.new(options: {"Status" => %w[Draft Published]}))

    assert_selector "optgroup[label='Status'] option[value='Draft']", text: "Draft"
  end

  # The blank belongs to the select, not to the first group.
  def test_include_blank_sits_outside_every_optgroup
    render_inline(UI::SelectComponent.new(options: {"Status" => %w[Draft]}, include_blank: true))

    assert_selector "select > option[value='']"
    assert_no_selector "optgroup option[value='']"
  end

  # AAA semantic tokens (the design-token guarantee), not raw Tailwind:
  def test_renders_with_aaa_tokens
    render_inline(UI::SelectComponent.new(options: %w[A B]))

    assert_selector "select.border-border-strong"
    assert_selector "select.focus-ring"
  end

  # WCAG 2.5.5 target size: the control sits at the 44px floor (--form-input-height).
  def test_meets_44px_target_floor
    render_inline(UI::SelectComponent.new(options: %w[A B]))

    assert_selector "select.min-h-input"
  end

  # invalid: drives a visible danger BORDER, not just aria-invalid. A border,
  # not a ring, because a box-shadow is not painted in forced-colors (#258).
  def test_invalid_carries_a_danger_border_token
    render_inline(UI::SelectComponent.new(options: %w[A B]))

    assert_selector "select.aria-invalid\\:border-danger"
  end

  def test_selected_marks_the_right_option
    render_inline(UI::SelectComponent.new(options: %w[Draft Published], selected: "Published"))

    assert_selector "select option[value='Published'][selected]", text: "Published"
    assert_no_selector "select option[value='Draft'][selected]"
  end

  def test_include_blank_adds_a_leading_blank_option
    render_inline(UI::SelectComponent.new(options: %w[Draft Published], include_blank: true))

    assert_selector "select option:first-child[value='']"
  end

  def test_invalid_sets_aria_invalid
    render_inline(UI::SelectComponent.new(options: %w[A B], invalid: true))

    assert_selector "select[aria-invalid='true']"
  end

  def test_not_invalid_omits_aria_invalid
    render_inline(UI::SelectComponent.new(options: %w[A B]))

    assert_no_selector "select[aria-invalid]"
  end

  def test_describedby_sets_aria_describedby
    render_inline(UI::SelectComponent.new(options: %w[A B], describedby: "status-error"))

    assert_selector "select[aria-describedby='status-error']"
  end

  def test_id_from_explicit_id_attr
    render_inline(UI::SelectComponent.new(options: %w[A B], id: "my_select"))

    assert_selector "select#my_select"
  end

  def test_id_falls_back_to_name
    render_inline(UI::SelectComponent.new(options: %w[A B], name: "post[status]"))

    assert_selector "select#post_status_"
  end

  def test_id_is_always_emitted_with_neither_id_nor_name
    render_inline(UI::SelectComponent.new(options: %w[A B]))

    assert_selector "select[id]"
  end

  def test_invalid_ring_has_a_width_not_just_a_color
    render_inline(UI::SelectComponent.new(options: %w[a], invalid: true))

    # The width is the half that survives forced-colors: the system repaints
    # every border, so a colour swap alone leaves valid and invalid identical
    # there. #112 asked the same question of a ring's width.
    assert_selector "select[class*='aria-invalid:border-2'][class*='aria-invalid:border-danger']"
  end
end
