# frozen_string_literal: true

require "render_test_helper"
load_component "file_input", "file_input_component.rb.tt"

class FileInputRenderTest < ViewComponent::TestCase
  def test_renders_a_file_input
    render_inline(UI::FileInputComponent.new)

    assert_selector "input[type='file']"
  end

  # AAA semantic tokens (the design-token guarantee), not raw Tailwind.
  # File inputs are state-independent (no NORMAL/ERROR swap) — styling lives in BASE.
  # Chained classes collapse the token set into single assertions.
  def test_renders_base_aaa_tokens
    render_inline(UI::FileInputComponent.new)

    assert_selector "input.block.w-full.text-text-body"
  end

  def test_renders_file_button_aaa_tokens
    render_inline(UI::FileInputComponent.new)

    assert_selector "input.file\\:bg-interactive.file\\:text-text-on-interactive.hover\\:file\\:bg-interactive-hover"
  end

  # A disabled file input is visually distinct.
  def test_renders_disabled_styling
    render_inline(UI::FileInputComponent.new)

    assert_selector "input.disabled\\:cursor-not-allowed.disabled\\:opacity-50"
  end

  # invalid: drives a visible danger ring, not just aria-invalid.
  def test_carries_a_danger_ring_token_for_invalid
    render_inline(UI::FileInputComponent.new)

    assert_selector "input.aria-invalid\\:ring-danger"
  end

  def test_accept_passes_through
    render_inline(UI::FileInputComponent.new(accept: "image/*"))

    assert_selector "input[type='file'][accept='image/*']"
  end

  def test_no_accept_by_default
    render_inline(UI::FileInputComponent.new)

    assert_no_selector "input[accept]"
  end

  def test_multiple_passes_through
    render_inline(UI::FileInputComponent.new(multiple: true))

    assert_selector "input[type='file'][multiple]"
  end

  def test_not_multiple_by_default
    render_inline(UI::FileInputComponent.new)

    assert_no_selector "input[multiple]"
  end

  # invalid: drives the server-validation-driven aria-invalid posture.
  def test_invalid_sets_aria_invalid
    render_inline(UI::FileInputComponent.new(invalid: true))

    assert_selector "input[type='file'][aria-invalid='true']"
  end

  def test_not_invalid_by_default
    render_inline(UI::FileInputComponent.new)

    assert_no_selector "input[aria-invalid='true']"
  end

  def test_required_sets_required_and_aria_required
    render_inline(UI::FileInputComponent.new(required: true))

    assert_selector "input[type='file'][required]"
    assert_selector "input[aria-required='true']"
  end

  def test_not_required_by_default
    render_inline(UI::FileInputComponent.new)

    assert_no_selector "input[required]"
    assert_no_selector "input[aria-required='true']"
  end

  def test_describedby_sets_aria_describedby
    render_inline(UI::FileInputComponent.new(describedby: "avatar_error"))

    assert_selector "input[type='file'][aria-describedby='avatar_error']"
  end

  def test_no_describedby_by_default
    render_inline(UI::FileInputComponent.new)

    assert_no_selector "input[aria-describedby]"
  end

  # --- show_selection: opt-in file-name display (STRUCTURE) ---
  # No JS runtime in render tests, so we assert the Stimulus wiring
  # (data-controller / values / targets / action) like range's show_value tests.

  # Default (show_selection omitted) is byte-unchanged: bare <input>, no wrapper.
  def test_default_renders_no_selection_wrapper
    render_inline(UI::FileInputComponent.new)

    assert_no_selector "[data-controller='file-input']"
    assert_no_selector "div"
  end

  def test_default_renders_no_selection_list_template_or_live_region
    render_inline(UI::FileInputComponent.new)

    assert_no_selector "ul", visible: :all
    assert_no_selector "template", visible: :all
    assert_no_selector "[aria-live]", visible: :all
  end

  def test_show_selection_wraps_input_in_file_input_controller
    render_inline(UI::FileInputComponent.new(show_selection: true))

    assert_selector "div[data-controller='file-input'] input[type='file']"
  end

  def test_show_selection_wires_input_target_and_change_action
    render_inline(UI::FileInputComponent.new(show_selection: true))

    assert_selector "input[data-file-input-target='input'][data-action~='change->file-input#update']"
  end

  def test_show_selection_carries_default_english_label_values
    render_inline(UI::FileInputComponent.new(show_selection: true))

    assert_selector "div[data-file-input-one-value='1 file selected: %{names}']"
    assert_selector "div[data-file-input-many-value='%{count} files selected: %{names}']"
    assert_selector "div[data-file-input-none-value='No files selected']"
  end

  # selection_labels merges over the English defaults (host supplies i18n strings).
  def test_selection_labels_override_reaches_the_data_values
    render_inline(UI::FileInputComponent.new(
      show_selection: true,
      selection_labels: {many: "%{count} Dateien: %{names}", none: "Keine Dateien"}
    ))

    assert_selector "div[data-file-input-many-value='%{count} Dateien: %{names}']"
    assert_selector "div[data-file-input-none-value='Keine Dateien']"
    assert_selector "div[data-file-input-one-value='1 file selected: %{names}']"
  end

  # The list starts hidden (the controller un-hides it once it holds pills).
  def test_show_selection_renders_hidden_list_target
    render_inline(UI::FileInputComponent.new(show_selection: true))

    assert_selector "ul[data-file-input-target='list'][hidden]", visible: :all
  end

  # Pill template reuses the badge soft chip treatment (proven AAA pairing:
  # bg-interactive-subtle + text-interactive — the badge [:soft, :primary] cell).
  # Capybara's HTML5 parse makes <template> content an inert fragment, so we
  # reach the pill through an HTML4 Nokogiri parse of the rendered output.
  def test_show_selection_pill_template_uses_badge_soft_chip_tokens
    render_inline(UI::FileInputComponent.new(show_selection: true))

    pill = Nokogiri::HTML4.fragment(rendered_content)
      .at_css("template[data-file-input-target=pill] > li")

    refute_nil pill
    %w[rounded-full bg-interactive-subtle text-interactive].each do |token|
      assert_includes pill["class"].split, token
    end
  end

  # The sr-only status live region is ALWAYS present in the DOM (a live region
  # that exists from page load announces reliably; un-hiding a populated one
  # does not — which is why status is separate from the visible list).
  def test_show_selection_renders_always_present_sr_only_live_region
    render_inline(UI::FileInputComponent.new(show_selection: true))

    assert_selector "span.sr-only[aria-live='polite'][data-file-input-target='status']"
  end

  # All existing attrs/html_attrs still land on the INPUT in wrapper mode.
  def test_show_selection_keeps_input_attrs_and_html_attrs_on_the_input
    render_inline(UI::FileInputComponent.new(
      show_selection: true, accept: "image/*", multiple: true, required: true,
      invalid: true, describedby: "gallery_error", name: "photos[]", id: "photos"
    ))

    assert_selector "div[data-controller='file-input'] " \
      "input[type='file'][accept='image/*'][multiple][required][aria-required='true']" \
      "[aria-invalid='true'][aria-describedby='gallery_error'][name='photos[]'][id='photos']"
  end

  def test_show_selection_keeps_aaa_tokens_on_the_input
    render_inline(UI::FileInputComponent.new(show_selection: true))

    assert_selector "div[data-controller='file-input'] input.block.w-full.text-text-body"
  end
end
