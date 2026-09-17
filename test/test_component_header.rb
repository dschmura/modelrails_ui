# frozen_string_literal: true

require "test_helper"
require "modelrails_ui/component_header"

class TestComponentHeader < Minitest::Test
  ABOVE = <<~RUBY.lines
    # frozen_string_literal: true

    module UI
      # # Toggle group
      #
      # A grouping of related toggle buttons wired to the `toggle-group`
      # Stimulus controller. Second sentence here.
      #
      # ## Use when
      # - You have a set of related on/off controls.
      #
      # ## Accessibility contract
      # - **Guarantees:** `role="group"` on the wrapper.
      class ToggleGroupComponent < ApplicationComponent
        def call = nil
      end
    end
  RUBY

  BELOW = <<~RUBY.lines
    # frozen_string_literal: true

    class UI::PictureComponent < ApplicationComponent
      # Each source is added via p.with_source(srcset:, type:, media:, sizes:)
      renders_many :sources
    end
  RUBY

  NONE = <<~RUBY.lines
    # frozen_string_literal: true

    module UI
      class KbdComponent < ApplicationComponent
      end
    end
  RUBY

  def test_locate_finds_a_block_above_the_class_line
    block = ModelrailsUi::ComponentHeader.locate(ABOVE)

    assert_equal :above, block.position
    assert_equal 3, block.start
    assert_equal 10, block.length
    assert_equal "  ", block.indent
    assert_equal "# Toggle group", block.text.first
  end

  def test_locate_finds_a_block_below_the_class_line
    block = ModelrailsUi::ComponentHeader.locate(BELOW)

    assert_equal :below, block.position
    assert_equal 3, block.start
    assert_equal 1, block.length
  end

  def test_locate_ignores_the_magic_comment_and_returns_nil_without_a_block
    assert_nil ModelrailsUi::ComponentHeader.locate(NONE)
  end

  def test_sections_split_intro_from_headed_sections
    intro, sections = ModelrailsUi::ComponentHeader.sections(ModelrailsUi::ComponentHeader.locate(ABOVE))

    assert_equal ["A grouping of related toggle buttons wired to the `toggle-group`",
      "Stimulus controller. Second sentence here."], intro
    assert_equal ["Use when", "Accessibility contract"], sections.map(&:heading)
    assert_equal ["- You have a set of related on/off controls."], sections.first.lines
  end

  def test_summary_is_the_first_sentence_of_the_intro
    intro, = ModelrailsUi::ComponentHeader.sections(ModelrailsUi::ComponentHeader.locate(ABOVE))

    assert_equal "A grouping of related toggle buttons wired to the `toggle-group` Stimulus controller.",
      ModelrailsUi::ComponentHeader.summary(intro)
  end

  def test_pointer_is_three_lines_naming_the_doc
    lines = ModelrailsUi::ComponentHeader.pointer(summary: "A thing.", doc: "toggle_group")

    assert_equal 3, lines.size
    assert_equal "A thing.", lines[0]
    assert_includes lines[1], "docs/components/toggle_group.md"
  end

  def test_pointer_predicate
    pointer_lines = ModelrailsUi::ComponentHeader.pointer(summary: "A thing.", doc: "toggle_group")
    source = ["module UI\n", *pointer_lines.map { |l| "  # #{l}\n" }, "  class ToggleGroupComponent\n", "  end\n", "end\n"]
    block = ModelrailsUi::ComponentHeader.locate(source)

    assert ModelrailsUi::ComponentHeader.pointer?(block, doc: "toggle_group")
    refute ModelrailsUi::ComponentHeader.pointer?(ModelrailsUi::ComponentHeader.locate(ABOVE), doc: "toggle_group")
    refute ModelrailsUi::ComponentHeader.pointer?(nil, doc: "toggle_group")
  end

  def test_doc_name_maps_sub_components_to_their_parent
    assert_equal "accordion", ModelrailsUi::ComponentHeader.doc_name("accordion_item")
    assert_equal "tabs", ModelrailsUi::ComponentHeader.doc_name("tabs_item")
    assert_equal "button", ModelrailsUi::ComponentHeader.doc_name("button")
    assert_equal "card", ModelrailsUi::ComponentHeader.doc_name("card_footer")
  end
end
