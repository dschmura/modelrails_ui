# frozen_string_literal: true

require "test_helper"
require "generators/modelrails_ui/components"

# COMPONENT_STATUS.md is human judgment (tier + notes), but its ROW SET is a
# fact: one row per supported component. Drift accumulated because nothing
# tied the two together (#133) — same spirit as the misfile invariants.
class TestComponentStatusLedger < Minitest::Test
  LEDGER = File.expand_path("../COMPONENT_STATUS.md", __dir__)

  # Ledger rows that are deliberately NOT template directories: sub-components
  # documented in their own row because they carry their own DoD evidence.
  SUBCOMPONENT_ROWS = %w[menubar_menu].freeze

  def rows
    @rows ||= File.readlines(LEDGER)
      .filter_map { |line| line[/\A\| ([a-z0-9_]+) \|/, 1] }
  end

  def supported
    ModelrailsUi::Generators::Components.supported
  end

  def test_every_supported_component_has_a_ledger_row
    missing = supported - rows

    assert_empty missing, "Components.supported entries with no COMPONENT_STATUS.md row: #{missing.inspect}"
  end

  def test_every_ledger_row_is_a_supported_component_or_a_declared_subcomponent
    unknown = rows - supported - SUBCOMPONENT_ROWS

    assert_empty unknown, "COMPONENT_STATUS.md rows that are not supported components: #{unknown.inspect}"
  end

  def test_rows_are_unique
    dupes = rows.tally.select { |_, n| n > 1 }.keys

    assert_empty dupes, "duplicate COMPONENT_STATUS.md rows: #{dupes.inspect}"
  end

  def test_the_prose_component_count_matches_the_row_count
    claims = File.read(LEDGER).scan(/all (\d+) components/).flatten.map(&:to_i)

    claims.each do |claim|
      assert_equal rows.size, claim,
        "ledger prose claims 'all #{claim} components' but the table has #{rows.size} rows"
    end
  end
end
