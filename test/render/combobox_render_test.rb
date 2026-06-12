# frozen_string_literal: true

require "render_test_helper"
load_component "combobox", "combobox_component.rb.tt"

# STRUCTURE-only render specs. The combobox is an autocomplete select: the text
# input is a `role="combobox"` controlling a `role="listbox"` of `role="option"`
# items, with the chosen value mirrored into a hidden field for form submission.
# Per the WAI-ARIA APG combobox pattern DOM focus stays on the input and the
# highlighted option is tracked via `aria-activedescendant` — that part is the
# `combobox` Stimulus controller's job and is proven by the app 0b in a real
# browser. Here we assert the server-rendered scaffolding: the combobox/listbox/
# option roles + wiring, an accessible name, AAA focus-ring (no box-shadow ring),
# semantic-token surfaces, html_attrs passthrough, and the fail-loud size enum.
class ComboboxRenderTest < ViewComponent::TestCase
  # The dropdown renders inside a `hidden` panel (toggled open by the controller),
  # so assert against the full DOM, not just visible nodes.
  def setup
    @prev_ignore_hidden = Capybara.ignore_hidden_elements
    Capybara.ignore_hidden_elements = false
  end

  def teardown
    Capybara.ignore_hidden_elements = @prev_ignore_hidden
  end

  OPTIONS = [
    {value: "us", label: "United States"},
    {value: "ca", label: "Canada"},
    {value: "mx", label: "Mexico"}
  ].freeze

  def render_basic(**opts)
    render_inline(UI::ComboboxComponent.new(name: "country", options: OPTIONS, **opts))
  end

  # --- combobox + listbox roles -------------------------------------------

  def test_input_is_a_combobox_controlling_the_listbox
    render_basic

    assert_selector(
      "input[role='combobox'][aria-expanded='false'][aria-controls='combobox-list'][aria-autocomplete='list']"
    )
  end

  def test_popup_is_a_named_listbox
    render_basic

    assert_selector "div#combobox-list[role='listbox'][aria-label]"
  end

  def test_options_are_listbox_options_with_aria_selected
    render_basic

    assert_selector "button[role='option'][aria-selected='false']", text: "United States"
    assert_selector "button[role='option'][aria-selected='false']", text: "Canada"
  end

  def test_preselected_value_marks_its_option_selected
    render_basic(value: "ca")

    assert_selector "button[role='option'][aria-selected='true']", text: "Canada"
    assert_selector "input[role='combobox'][value='Canada']"
    assert_selector "input[type='hidden'][name='country'][value='ca']", visible: false
  end

  # --- accessible name -----------------------------------------------------

  def test_combobox_has_an_i18n_default_accessible_name
    render_basic

    assert_selector "input[role='combobox'][aria-label='Search and select an option']"
  end

  def test_label_overrides_the_accessible_name
    render_basic(label: "Country")

    assert_selector "input[role='combobox'][aria-label='Country']"
    assert_selector "div[role='listbox'][aria-label='Country']"
  end

  def test_default_placeholder_is_i18n
    render_basic

    assert_selector "input[role='combobox'][placeholder='Select…']"
  end

  # --- wiring --------------------------------------------------------------

  def test_root_is_wired_to_the_combobox_controller
    render_basic

    assert_selector "div[data-controller='combobox']"
    assert_selector "input[data-combobox-target='input'][data-action*='combobox#navigate']"
    assert_selector "div[data-combobox-target='list']"
  end

  def test_empty_state_is_an_i18n_live_region
    render_basic

    assert_selector "div[role='status'][data-combobox-target='empty']", text: "No results found.", visible: false
  end

  # --- focus-ring (AAA) ----------------------------------------------------

  def test_input_and_options_carry_the_focus_ring
    render_basic

    assert_selector "input[role='combobox'].focus-ring"
    assert_selector "button[role='option'].focus-ring"
  end

  # Regression guard: the box-shadow ring / outline-none anti-pattern must not return.
  def test_no_box_shadow_ring_or_outline_none
    render_basic
    html = page.native.to_html

    refute_includes html, "focus-visible:ring-"
    refute_includes html, "focus:ring-"
    refute_includes html, "outline-none"
  end

  # --- semantic tokens (no raw palette) -----------------------------------

  def test_renders_with_aaa_semantic_tokens
    render_basic

    assert_selector "div.bg-surface-overlay"
    assert_selector "input.text-text-body"
    # `aria-selected:` active-option styling reads off the surface ramp, not raw palette.
    assert_selector "button[class*='aria-selected:bg-surface-sunken']"
  end

  # --- size enum -----------------------------------------------------------

  def test_default_size_is_md
    render_basic

    assert_selector "input[role='combobox'].h-9"
  end

  def test_size_lg_grows_the_input
    render_basic(size: :lg)

    assert_selector "input[role='combobox'].h-10"
  end

  def test_unknown_size_raises
    assert_raises(ArgumentError) do
      render_basic(size: :bogus)
    end
  end

  # --- html_attrs passthrough ---------------------------------------------

  # html_attrs pass through onto the root WITHOUT clobbering the controller wiring:
  # a caller `data:` is merged, so `data-controller='combobox'` survives.
  def test_passes_through_html_attrs_preserving_the_controller
    render_inline(
      UI::ComboboxComponent.new(name: "country", options: OPTIONS, id: "country-cb", data: {testid: "cb"})
    )

    assert_selector "div#country-cb[data-controller='combobox'][data-testid='cb']"
  end

  # A caller-supplied class merges onto the root without clobbering the relative anchor.
  def test_merges_caller_class_onto_the_root
    render_basic(class: "mt-4")

    assert_selector "div.mt-4.relative"
  end
end
