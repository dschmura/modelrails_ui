# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require "modelrails_ui/prose_stats"

class TestProseStats < Minitest::Test
  def with_files
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, "a_component.rb"), "module UI\n  # # A\n  #\n  # Desc.\n  class AComponent\n    x = 1 # inline\n  end\nend\n")
      File.write(File.join(dir, "a_component_preview.rb"), "# @label A\n# Class note.\nclass ACP\n  # @param x\n  # scenario note\n  def default; end\nend\n")
      yield dir
    end
  end

  def test_component_row_counts_lines_comments_and_header
    with_files do |dir|
      row = ModelrailsUi::ProseStats.component_row("x", [File.join(dir, "a_component.rb")])

      assert_equal 1, row.files
      assert_equal 8, row.lines
      assert_equal 3, row.comment_lines
      assert_equal 3, row.header_lines
    end
  end

  def test_preview_row_splits_annotations_class_notes_and_scenario_notes
    with_files do |dir|
      row = ModelrailsUi::ProseStats.preview_row("p", [File.join(dir, "a_component_preview.rb")])

      assert_equal 2, row.annotations
      assert_equal 1, row.class_notes
      assert_equal 1, row.scenario_notes
    end
  end

  def test_table_renders_one_line_per_row
    with_files do |dir|
      rows = [ModelrailsUi::ProseStats.component_row("x", [File.join(dir, "a_component.rb")])]
      out = ModelrailsUi::ProseStats.table(rows)

      assert_match(/^x\s+files=1\s+lines=8\s+comment=3 \(38%\)\s+header=3 \(38%\)$/, out)
    end
  end
end
