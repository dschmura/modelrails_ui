# frozen_string_literal: true

require "render_test_helper"
load_component "data_table", "data_table_component.rb.tt"

# STRUCTURE-only render tests. The data-table Stimulus controller's behavior
# (aria-sort flipping on click, the live region announcing result counts on
# filter, page-label interpolation) is verified by an app-level 0b browser
# spec — the render harness CANNOT exercise JS, so we assert the static
# scaffolding the controller relies on, never the runtime behavior itself.
class DataTableRenderTest < ViewComponent::TestCase
  COLUMNS = [
    {key: :name, label: "Name", sortable: true},
    {key: :email, label: "Email", sortable: true},
    {key: :role, label: "Role"} # non-sortable
  ].freeze

  ROWS = [
    {name: "Ada", email: "ada@example.com", role: "Admin"},
    {name: "Babbage", email: "chuck@example.com", role: "Member"}
  ].freeze

  def render_default(**overrides)
    render_inline(UI::DataTableComponent.new(columns: COLUMNS, rows: ROWS, **overrides))
  end

  # --- Keyboard-operable sort header + aria-sort -----------------------------

  # A sortable column renders th[aria-sort='none'] containing a focusable
  # <button> that carries the sort action + key param. The button (not the th)
  # is keyboard-operable for free.
  def test_sortable_header_is_a_button_inside_an_aria_sort_th
    render_default

    assert_selector "th[aria-sort='none'] button[type='button'][data-action~='click->data-table#sort']"
    assert_selector "th[aria-sort='none'] button[data-data-table-key-param='name']"
    assert_selector "th[aria-sort='none'] button[data-data-table-key-param='email']"
  end

  # The click handler must live on the BUTTON, not the (non-focusable) <th>.
  def test_sort_action_is_not_on_the_th_itself
    render_default

    assert_no_selector "th[data-action~='click->data-table#sort']"
  end

  # Non-sortable columns stay a plain <th> with no aria-sort and no sort button.
  def test_non_sortable_header_has_no_aria_sort_and_no_button
    render_default

    role_th = page.find("th", text: "Role")

    assert_nil role_th[:"aria-sort"], "non-sortable th must not advertise aria-sort"
    assert_no_selector "th button[data-data-table-key-param='role']"
  end

  # --- Live region for result count -----------------------------------------

  # An always-present visually-hidden polite status region the controller
  # writes the localized result count into on filter/sort/page.
  def test_renders_a_polite_status_live_region
    render_default

    assert_selector "div[role='status'][aria-live='polite'].sr-only[data-data-table-target='status']"
  end

  # --- 44px AAA targets (WCAG 2.5.5) -----------------------------------------

  def test_pager_buttons_are_44px
    render_default(per_page: 1)

    assert_selector "button.h-11.w-11", minimum: 2 # prev + next
  end

  def test_search_control_is_44px_tall
    render_default

    assert_selector "label.h-11" # the search wrapper row
  end

  def test_sortable_header_button_is_at_least_44px_tall
    render_default

    # The header button fills the (>=44px) cell height.
    assert_selector "th button.min-h-11"
  end

  # --- AAA semantic tokens, not raw Tailwind ---------------------------------

  def test_renders_with_aaa_semantic_tokens
    render_default

    assert_selector "div.border-border"        # wrapper
    assert_selector "th.text-text-muted"        # header cell
  end

  # --- i18n: server-rendered defaults ----------------------------------------

  def test_search_input_has_default_placeholder_and_accessible_name
    render_default

    assert_selector "input[type='search'][placeholder='Search…']"
    assert_selector "input[type='search'][aria-label='Search']"
  end

  def test_pager_aria_labels_render_defaults
    render_default(per_page: 1)

    assert_selector "button[aria-label='Previous page']"
    assert_selector "button[aria-label='Next page']"
  end

  # --- i18n: JS templates exposed as data attributes on the root -------------

  # The controller interpolates these %{...} templates client-side; the render
  # harness only asserts they are present with their default English text.
  def test_js_interpolation_templates_are_on_the_root
    render_default

    root = page.find("div[data-controller~='data-table']")

    assert_equal "%{count} results", root["data-data-table-results-template"]
    assert_equal "Page %{page} of %{pages} (%{rows} rows)", root["data-data-table-page-template"]
  end

  # --- Rows / cells / caption ------------------------------------------------

  def test_renders_rows_and_cells
    render_default

    assert_selector "tbody tr[data-data-table-row]", count: 2
    assert_selector "td", text: "ada@example.com"
    assert_selector "td", text: "Admin"
  end

  def test_renders_caption_when_given
    render_default(caption: "Active users")

    assert_selector "caption", text: "Active users"
  end

  def test_no_caption_by_default
    render_default

    assert_no_selector "caption"
  end
end
