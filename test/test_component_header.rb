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

  # A title-led header severed from the class line by constants in between
  # (card_title's real shape: header, then LEVELS/DEFAULT_LEVEL, then class).
  TITLE_LED_SEVERED = <<~RUBY.lines
    # frozen_string_literal: true

    module UI
      # # Card title
      #
      # The heading inside a card, defaulting to h3.
      LEVELS = (1..6).freeze
      DEFAULT_LEVEL = 3

      class CardTitleComponent < ApplicationComponent
        def call = nil
      end
    end
  RUBY

  # An already-migrated pointer above the class, next to a longer below-class
  # implementation comment that would otherwise win a naive size comparison.
  POINTER_ABOVE_LONGER_BELOW = <<~RUBY.lines
    # frozen_string_literal: true

    module UI
      # A labelled radio group.
      # Usage, options and the accessibility contract: docs/components/radio_group.md in the
      # modelrails_ui gem (`bundle show modelrails_ui`); live examples in Lookbook.
      class RadioGroupComponent < ApplicationComponent
        # items: [{ value:, label:, checked: (optional), disabled: (optional) }]
        #
        # Group accessibility/form params, mirroring the shared form-control API:
        #   label:       sets the group's accessible name via `aria-label`
        #   labelledby:  sets `aria-labelledby` (point at a visible heading's id instead)
        def initialize(name:); end
      end
    end
  RUBY

  COLON_HEADING_SOURCE = <<~RUBY.lines
    # frozen_string_literal: true

    module UI
      # A single accordion row, rendered as a native <details>/<summary> disclosure.
      #
      # Accessibility contract:
      # - Native <details>/<summary> carries the disclosure semantics.
      class AccordionItemComponent < ApplicationComponent
        def call = nil
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

  def test_locate_finds_a_title_led_header_severed_from_the_class_by_constants
    block = ModelrailsUi::ComponentHeader.locate(TITLE_LED_SEVERED)

    assert_equal :above, block.position
    assert_equal 3, block.start
    assert_equal 3, block.length
    assert_equal "# Card title", block.text.first
  end

  def test_locate_prefers_an_above_pointer_over_a_longer_below_class_comment
    block = ModelrailsUi::ComponentHeader.locate(POINTER_ABOVE_LONGER_BELOW)

    assert_equal :above, block.position
    assert_equal 3, block.start
    assert_equal 3, block.length
    assert_includes block.text[1], "docs/components/radio_group.md"
  end

  def test_sections_recognizes_a_colon_style_heading_without_markdown
    intro, sections = ModelrailsUi::ComponentHeader.sections(ModelrailsUi::ComponentHeader.locate(COLON_HEADING_SOURCE))

    assert_equal ["A single accordion row, rendered as a native <details>/<summary> disclosure."], intro
    assert_equal ["Accessibility contract"], sections.map(&:heading)
    assert_equal ["- Native <details>/<summary> carries the disclosure semantics."], sections.first.lines
  end

  def test_summary_does_not_truncate_on_an_abbreviation_period
    intro = ["Wraps `f.email_field`/etc. into a labelled control."]

    assert_equal "Wraps `f.email_field`/etc. into a labelled control.",
      ModelrailsUi::ComponentHeader.summary(intro)
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

  def test_pointer_predicate_requires_exactly_three_lines
    two_line = ModelrailsUi::ComponentHeader::Block.new(
      start: 0, length: 2,
      lines: ["  # A thing.\n", "  # docs/components/toggle_group.md in the modelrails_ui gem.\n"],
      position: :above, indent: "  "
    )
    one_line = ModelrailsUi::ComponentHeader::Block.new(
      start: 0, length: 1,
      lines: ["  # docs/components/toggle_group.md in the modelrails_ui gem.\n"],
      position: :above, indent: "  "
    )

    refute ModelrailsUi::ComponentHeader.pointer?(two_line, doc: "toggle_group")
    refute ModelrailsUi::ComponentHeader.pointer?(one_line, doc: "toggle_group")
  end

  def test_doc_name_maps_sub_components_to_their_parent
    assert_equal "accordion", ModelrailsUi::ComponentHeader.doc_name("accordion_item")
    assert_equal "tabs", ModelrailsUi::ComponentHeader.doc_name("tabs_item")
    assert_equal "button", ModelrailsUi::ComponentHeader.doc_name("button")
    assert_equal "card", ModelrailsUi::ComponentHeader.doc_name("card_footer")
  end

  def test_stated_in_recognizes_a_fact_folded_into_a_markdown_table_row
    line = "`type`: `:single` (one active) or `:multiple` (many active)"
    corpus = "| `type` | Symbol | `:single` | `:single` (one active) or `:multiple` (many active) |"

    assert ModelrailsUi::ComponentHeader.stated_in?(line, corpus)
  end

  def test_stated_in_is_false_for_an_unrelated_line
    corpus = "| `type` | Symbol | `:single` | `:single` (one active) or `:multiple` (many active) |"

    refute ModelrailsUi::ComponentHeader.stated_in?("An entirely unrelated sentence about widgets and gadgets.", corpus)
  end

  def test_stated_in_falls_back_to_containment_for_a_line_under_four_words
    assert ModelrailsUi::ComponentHeader.stated_in?("live region.", "The panel is a live region.")
    refute ModelrailsUi::ComponentHeader.stated_in?("live region.", "unrelated text")
  end
end
