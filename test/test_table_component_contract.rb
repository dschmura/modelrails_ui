# frozen_string_literal: true

require "test_helper"
require "yaml"
require_relative "../lib/generators/modelrails_ui/components"

# Text-level contract for the server-rendered `table`. The render lane proves what
# the component emits; these hold the two things that live OUTSIDE the component
# file and would otherwise drift silently.
class TestTableComponentContract < Minitest::Test
  Components = ModelrailsUi::Generators::Components

  LOCALE_FILE = File.expand_path(
    "../lib/generators/modelrails_ui/install/templates/modelrails_ui.en.yml", __dir__
  )

  def locale = YAML.load_file(LOCALE_FILE).fetch("en").fetch("modelrails_ui")

  # `table` renders UI::ScrollAreaComponent when `scroll:` is given, so
  # `add table` in a bare app installs a file that NameErrors on first render
  # unless the dependency is declared — the same failure the form_builder entry
  # exists to prevent.
  def test_table_declares_its_scroll_area_dependency
    assert_includes Components.expand(%w[table]), "scroll_area",
      "add table must also install scroll_area — table renders it for scroll: :horizontal"
  end

  def test_table_is_a_supported_component
    assert_includes Components.supported, "table"
  end

  # The delegate-file contract: a component's user-facing string carries an inline
  # English default AND has its key in the host-owned locale file, so a host can
  # translate it without forking the component.
  def test_lists_the_scroll_region_key_in_the_delegate_file
    assert_equal "%{name}, scrolls sideways", locale.dig("table", "scroll_region"),
      "the table's scroll-region name must be overridable from the delegate locale file"
  end

  # The name is interpolated with the caption; dropping %{name} would leave every
  # scrollable table on a page with the same region name.
  def test_the_scroll_region_name_interpolates_the_caption
    assert_includes locale.dig("table", "scroll_region"), "%{name}"
  end
end
