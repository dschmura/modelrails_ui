# frozen_string_literal: true

require "render_test_helper"
load_component "command", "command_component.rb.tt"

# STRUCTURE-only render specs. The command palette is a combobox (the search
# input) controlling a listbox (the item list); per the WAI-ARIA APG combobox
# pattern, DOM focus stays on the input and the highlighted option is tracked via
# `aria-activedescendant` — that part is the `command` Stimulus controller's job
# and is proven by the app 0b in a real browser. Here we assert the server-rendered
# scaffolding: the combobox/listbox roles + wiring, AAA focus-ring on items, the
# semantic-token surfaces (no raw palette), html_attrs passthrough, and the
# fail-loud size enum.
class CommandRenderTest < ViewComponent::TestCase
  # The whole palette renders inside a `hidden` panel (it's toggled open by the
  # controller), so assert against the full DOM, not just visible nodes.
  def setup
    @prev_ignore_hidden = Capybara.ignore_hidden_elements
    Capybara.ignore_hidden_elements = false
  end

  def teardown
    Capybara.ignore_hidden_elements = @prev_ignore_hidden
  end

  # Caller-supplied item markup, authored with the exposed CSS constants exactly
  # as the docs/usage prescribe.
  def render_basic(**opts)
    render_inline(UI::CommandComponent.new(**opts)) do
      <<~HTML.html_safe
        <div class="#{UI::CommandComponent::GROUP_WRAPPER}" data-command-group>
          <p class="#{UI::CommandComponent::GROUP}">Pages</p>
          <button type="button" class="#{UI::CommandComponent::ITEM}" data-command-value="Dashboard">
            Dashboard
            <span class="#{UI::CommandComponent::SHORTCUT}">⌘D</span>
          </button>
          <button type="button" class="#{UI::CommandComponent::ITEM}" data-command-value="Settings">Settings</button>
        </div>
      HTML
    end
  end

  def test_renders_a_root_wired_to_the_command_controller
    render_basic

    assert_selector "div[data-controller='command']"
    assert_selector "div[data-command-target='panel'][hidden]"
  end

  # The search input is the combobox: it controls the listbox and advertises
  # list-style autocomplete. DOM focus stays here (activedescendant pattern).
  def test_input_is_a_combobox_controlling_the_listbox
    render_basic

    assert_selector "input[role='combobox'][aria-controls='command-list'][aria-autocomplete='list'][aria-expanded='true']"
    assert_selector "input[data-command-target='input']"
  end

  # The input is named (no visible <label>), so it has an accessible name, and the
  # keyboard nav action is wired.
  def test_input_is_named_and_wired_for_navigation
    render_basic

    assert_selector "input[role='combobox'][aria-label='Search commands']"
    assert_selector "input[data-action~='keydown->command#navigate']"
  end

  # The list is the listbox the combobox points at — same id, with an accessible name.
  def test_list_is_a_named_listbox_matching_the_combobox
    render_basic

    assert_selector "div#command-list[role='listbox'][aria-label='Commands'][data-command-target='list']"
  end

  # The dialog is a labelled modal.
  def test_panel_is_a_labelled_modal_dialog
    render_basic

    assert_selector "div[role='dialog'][aria-modal='true'][aria-label='Command palette']"
  end

  # The empty-state is an i18n-labelled live region (announced when no match).
  def test_empty_state_is_an_i18n_live_region
    render_basic

    assert_selector "div[role='status'][data-command-target='empty'][hidden]", text: "No results found."
  end

  # AAA focus-ring (offset outline) on each actionable item — never a box-shadow ring.
  def test_items_carry_the_focus_ring
    render_basic

    assert_selector "button.focus-ring[data-command-value='Dashboard']", text: "Dashboard"
    assert_selector "button.focus-ring[data-command-value='Settings']", text: "Settings"
  end

  # Semantic AAA tokens, not raw palette: the panel sits on the overlay surface and
  # the scrim uses the neutral ramp (no literal `bg-black`).
  def test_renders_with_semantic_tokens_not_raw_palette
    render_basic
    html = page.native.to_html

    assert_selector "div.bg-surface-overlay[role='dialog']"
    assert_includes html, "bg-neutral-950/80"
    refute_includes html, "bg-black"
  end

  # The active-option highlight style is present on items so pointer + keyboard
  # selection share one visual (the controller toggles aria-selected). The `[`
  # arbitrary-variant class must survive tailwind_merge.
  def test_items_style_the_active_option_via_aria_selected
    render_basic

    assert_selector "button[class*='aria-selected:bg-surface-sunken'][data-command-value='Dashboard']"
  end

  # Regression guard: the box-shadow ring / outline-none anti-pattern must not return.
  def test_no_box_shadow_ring
    render_basic
    html = page.native.to_html

    refute_includes html, "focus-visible:ring-"
    refute_includes html, "focus:ring-"
  end

  # The trigger slot opens the palette on click.
  def test_trigger_slot_opens_the_palette
    render_inline(UI::CommandComponent.new) do |cmd|
      cmd.with_trigger { "⌘K".html_safe }
    end

    assert_selector "span[data-action='click->command#open']", text: "⌘K"
  end

  # --- size enum -----------------------------------------------------------

  def test_default_size_is_md
    render_basic

    assert_selector "div[role='dialog'].max-w-lg"
  end

  def test_size_lg_widens_the_panel
    render_basic(size: :lg)

    assert_selector "div[role='dialog'].max-w-2xl"
  end

  def test_unknown_size_raises
    assert_raises(ArgumentError) do
      render_basic(size: :bogus)
    end
  end

  # --- html_attrs passthrough ---------------------------------------------

  # html_attrs pass through onto the root, matching the sibling components.
  def test_passes_through_html_attrs_onto_the_root
    render_inline(UI::CommandComponent.new(id: "app-command", data: {testid: "cmd"}))

    assert_selector "div#app-command[data-controller='command'][data-testid='cmd']"
  end

  # A caller-supplied class merges onto the panel without clobbering the surface token.
  def test_merges_caller_class_onto_the_panel
    render_inline(UI::CommandComponent.new(class: "max-w-3xl"))

    assert_selector "div[role='dialog'].max-w-3xl.bg-surface-overlay"
  end
end
