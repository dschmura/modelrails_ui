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

  # AAA semantic tokens (the design-token guarantee), not raw Tailwind:
  def test_renders_with_aaa_tokens
    render_inline(UI::SelectComponent.new(options: %w[A B]))

    assert_selector "select.border-border-strong"
    assert_selector "select.focus\\:ring-interactive-focus"
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
end
