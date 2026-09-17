# frozen_string_literal: true

require "test_helper"
require "modelrails_ui/component_header/migrator"

class TestComponentHeaderMigrator < Minitest::Test
  M = ModelrailsUi::ComponentHeader::Migrator

  SOURCE = <<~RUBY.lines
    # frozen_string_literal: true

    module UI
      # # Toggle group
      #
      # A grouping of related toggle buttons. Second sentence.
      #
      # ## Use when
      # - You have a set of related on/off controls.
      #
      # ## Don't use when
      # - It's a single standalone control.
      #
      # ## Accessibility contract
      # - **Guarantees:** `role="group"` on the wrapper.
      class ToggleGroupComponent < ApplicationComponent
        def call = nil
      end
    end
  RUBY

  DOC = <<~MD
    # Toggle group

    Intro paragraph.

    ## Usage

    Some usage.

    ## API

    | Option | Type |
    |---|---|
  MD

  def test_migrate_replaces_the_header_with_the_pointer_and_keeps_the_rest
    lines, = M.migrate("toggle_group", SOURCE, DOC)

    assert_equal "  # A grouping of related toggle buttons.\n", lines[3]
    assert_includes lines[4], "docs/components/toggle_group.md"
    assert_equal "  class ToggleGroupComponent < ApplicationComponent\n", lines[6]
    assert_equal SOURCE.size - 9, lines.size
  end

  def test_migrate_appends_mapped_sections_to_the_doc
    _, doc = M.migrate("toggle_group", SOURCE, DOC)

    assert_includes doc, "## When to use\n\n- You have a set of related on/off controls.\n"
    assert_includes doc, "## When not to use\n\n- It's a single standalone control.\n"
    assert_includes doc, "## Accessibility contract\n\n- **Guarantees:** `role=\"group\"` on the wrapper.\n"
    assert_operator doc.index("## API"), :<, doc.index("## When to use"), "moved sections go after the existing doc"
  end

  def test_migrate_is_idempotent
    lines, doc = M.migrate("toggle_group", SOURCE, DOC)
    again_lines, again_doc = M.migrate("toggle_group", lines, doc)

    assert_equal lines, again_lines
    assert_equal doc, again_doc
  end

  def test_sub_component_sections_are_prefixed_in_the_parent_doc
    src = SOURCE.map { |l| l.sub("ToggleGroupComponent", "TabsItemComponent") }
    lines, doc = M.migrate("tabs_item", src, DOC)

    assert_includes lines[4], "docs/components/tabs.md"
    assert_includes doc, "## Tabs item: When to use"
  end

  def test_append_section_reuses_an_existing_heading
    doc = "# X\n\n## Accessibility contract\n\n- existing line\n\n## API\n\ntable\n"
    out = M.append_section(doc, "Accessibility contract", ["- new line"])

    assert_equal 1, out.scan("## Accessibility contract").size
    assert_includes out, "- existing line\n\n- new line\n\n## API"
  end

  def test_headerless_source_gets_a_pointer_with_the_docs_first_sentence
    src = ["# frozen_string_literal: true\n", "\n", "module UI\n", "  class KbdComponent < ApplicationComponent\n", "  end\n", "end\n"]
    lines, doc = M.migrate("kbd", src, "# Kbd\n\nRenders a keyboard key. More.\n")

    assert_equal "  # Renders a keyboard key.\n", lines[3]
    assert_equal "  class KbdComponent < ApplicationComponent\n", lines[6]
    assert_equal "# Kbd\n\nRenders a keyboard key. More.\n", doc
  end

  def test_missing_from_doc_names_sections_the_doc_does_not_carry
    block = ModelrailsUi::ComponentHeader.locate(SOURCE)

    assert_equal ["Use when", "Don't use when", "Accessibility contract"], M.missing_from_doc(block, DOC)
    _, doc = M.migrate("toggle_group", SOURCE, DOC)

    assert_empty M.missing_from_doc(block, doc)
  end
end
