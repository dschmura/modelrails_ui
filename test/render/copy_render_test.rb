# frozen_string_literal: true

require "render_test_helper"
load_component "input", "input_component.rb.tt"
load_component "button", "button_component.rb.tt"
load_component "copy", "copy_component.rb.tt"

class CopyRenderTest < ViewComponent::TestCase
  URL = "https://example.test/invitations/abc123/accept"

  def render_copy(**opts)
    render_inline(UI::CopyComponent.new(value: URL, label: "Invitation link", **opts))
  end

  def test_renders_a_readonly_input_holding_the_value_with_no_name
    render_copy

    assert_selector "input[type='text'][readonly][value='#{URL}'][data-copy-target='source'][data-slot='copy-value']"
    assert_no_selector "input[name]"
  end

  def test_value_uses_the_input_component_chrome_not_form_input
    render_copy

    assert_selector "input.bg-surface-raised.text-text-heading.font-mono"
    assert_no_selector "input.form-input"
  end

  def test_label_is_a_real_label_for_the_input
    render_copy
    id = page.find("input[data-copy-target='source']")[:id]

    assert_selector "label[for='#{id}'][data-slot='label']", text: "Invitation link"
  end

  def test_label_hidden_renders_sr_only
    render_copy(label_hidden: true)

    assert_selector "label.sr-only", text: "Invitation link", visible: :all
  end

  def test_trigger_accessible_name_contains_the_visible_action
    render_copy

    assert_selector "button[type='button'][aria-label='Copy Invitation link'][data-action='copy#copy'][data-slot='copy-trigger']",
      text: "Copy"
  end

  def test_trigger_uses_the_outline_neutral_cell
    render_copy

    assert_selector "button.btn-secondary"
  end

  def test_both_regions_exist_empty_at_first_render
    render_copy

    assert_selector "p[role='status'][aria-live='polite'][aria-atomic='true'][data-copy-target='status'][data-slot='copy-status']",
      exact_text: ""
    assert_selector "p[role='alert'][data-copy-target='error'][data-slot='copy-error']", exact_text: ""
  end

  def test_wrapper_carries_controller_state_and_the_two_announcement_strings
    render_copy
    wrapper = page.find("div[data-controller='copy'][data-slot='control'][data-state='idle']")

    assert_equal "Copied Invitation link to the clipboard", wrapper["data-copy-copied-value"]
    assert_equal "Couldn't copy automatically. Invitation link is selected — use your browser or device copy command.",
      wrapper["data-copy-failed-value"]
  end

  def test_announcement_strings_name_no_keystroke_and_never_the_value
    render_copy
    wrapper = page.find("div[data-controller='copy'][data-slot='control'][data-state='idle']")

    refute_includes wrapper["data-copy-failed-value"], "Ctrl"
    refute_includes wrapper["data-copy-copied-value"], "https://"
  end

  def test_describedby_and_autofocus_land_on_the_button_not_the_input
    render_copy(describedby: "warning-1", autofocus: true)

    assert_selector "button[aria-describedby='warning-1'][autofocus]"
    assert_no_selector "input[aria-describedby]"
    assert_no_selector "input[autofocus]"
  end

  def test_caller_data_and_class_survive_alongside_the_controller
    render_copy(data: {testid: "share"}, class: "mt-4")

    assert_selector "div.mt-4[data-controller='copy'][data-testid='share']"
  end

  def test_two_instances_have_distinct_ids_and_an_explicit_id_wins
    a = render_inline(UI::CopyComponent.new(value: "a", label: "A")).css("input").first["id"]
    b = render_inline(UI::CopyComponent.new(value: "b", label: "B")).css("input").first["id"]
    c = render_inline(UI::CopyComponent.new(value: "c", label: "C", id: "copy-c")).css("input").first["id"]

    refute_equal a, b
    assert_equal "copy-c", c
  end

  def test_icons_are_decorative_and_only_the_copy_glyph_is_visible_at_rest
    render_copy

    assert_selector "svg[aria-hidden='true'][focusable='false'][data-copy-target='copyIcon']:not([hidden])", visible: :all
    assert_selector "svg[aria-hidden='true'][focusable='false'][hidden][data-copy-target='successIcon']", visible: :all
  end

  def test_per_call_labels_override_the_defaults
    render_copy(copy_label: "Grab", copied_label: "Grabbed", failed_label: "Nope")
    wrapper = page.find("div[data-controller='copy']")

    assert_selector "button[aria-label='Grab Invitation link']", text: "Grab"
    assert_equal "Grabbed", wrapper["data-copy-copied-value"]
    assert_equal "Nope", wrapper["data-copy-failed-value"]
  end

  def test_host_locale_overrides_the_gem_defaults
    I18n.backend.store_translations(:en, modelrails_ui: {copy: {action: "Copy it", copied: "Got %{label}"}})
    render_copy
    wrapper = page.find("div[data-controller='copy']")

    assert_selector "button[aria-label='Copy it Invitation link']", text: "Copy it"
    assert_equal "Got Invitation link", wrapper["data-copy-copied-value"]
  ensure
    I18n.backend.reload!
  end
end
