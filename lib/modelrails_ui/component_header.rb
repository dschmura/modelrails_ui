# frozen_string_literal: true

module ModelrailsUi
  # The class-level doc comment of a component file: the contiguous `#` block
  # adjacent to the `class` line, above it (inside `module UI`) or directly
  # below it. Read-only; rewriting lives in ComponentHeader::Migrator.
  module ComponentHeader
    Block = Data.define(:start, :length, :lines, :position, :indent) do
      # Comment text with the leading `# ` removed, one string per line.
      def text = lines.map { |l| l.sub(/\A\s*# ?/, "").rstrip }
    end

    Section = Data.define(:heading, :lines)

    # Sub-components documented on their parent's page.
    DOC_PARENT = {
      "accordion_item" => "accordion",
      "card_content" => "card",
      "card_description" => "card",
      "card_footer" => "card",
      "card_header" => "card",
      "card_title" => "card",
      "list_group_item" => "list_group",
      "menubar_menu" => "menubar",
      "tabs_item" => "tabs"
    }.freeze

    module_function

    def doc_name(component) = DOC_PARENT.fetch(component, component)

    # Returns a Block, or nil when the file has no class-level comment.
    def locate(lines)
      i = lines.index { |l| l.match?(/\A\s*class\s+\S/) } or return nil

      up_start = i
      up_start -= 1 while up_start.positive? && lines[up_start - 1].match?(/\A\s*#/)
      up = lines[up_start...i]
      up = [] if up.any? { |l| l.include?("frozen_string_literal") }

      down_end = i + 1
      down_end += 1 while down_end < lines.size && lines[down_end].match?(/\A\s*#/)
      down = lines[(i + 1)...down_end]

      # An already-migrated pointer is always ≤3 lines above the class — shorter than
      # an unrelated below-class implementation comment (e.g. documenting an
      # `initialize` param shape) can be. Once a pointer is in place, it wins outright
      # rather than losing the general above-vs-below size comparison below.
      if up.any? { |l| l.include?("Usage, options and the accessibility contract: docs/components/") }
        return Block.new(start: up_start, length: up.size, lines: up, position: :above, indent: up.first[/\A\s*/])
      end

      if up.size >= down.size
        return nil if up.empty?

        Block.new(start: up_start, length: up.size, lines: up, position: :above, indent: up.first[/\A\s*/])
      else
        Block.new(start: i + 1, length: down.size, lines: down, position: :below, indent: down.first[/\A\s*/])
      end
    end

    # Splits the block into [intro_lines, [Section]]. Drops a leading "# Title"
    # line; trims blank lines around every part.
    def sections(block)
      text = block.text
      text = text.drop(1) if text.first.to_s.match?(/\A#\s+\S/)
      intro = []
      out = []
      heading = nil
      body = []
      flush = lambda do
        out << Section.new(heading: heading, lines: trim(body)) if heading
        body = []
      end
      text.each do |line|
        if (m = line.match(/\A##\s+(.+)\z/))
          flush.call
          heading = m[1].strip
        elsif heading
          body << line
        else
          intro << line
        end
      end
      flush.call
      [trim(intro), out]
    end

    # First sentence of the intro's first paragraph.
    def summary(intro)
      para = intro.drop_while(&:empty?).take_while { |l| !l.empty? }.join(" ")
      para[/\A.*?[.!?](?=\s|\z)/] || para
    end

    # The three-line header every component carries after migration.
    def pointer(summary:, doc:)
      [
        summary,
        "Usage, options and the accessibility contract: docs/components/#{doc}.md in the",
        "modelrails_ui gem (`bundle show modelrails_ui`); live examples in Lookbook."
      ]
    end

    def pointer?(block, doc:)
      !block.nil? && block.length <= 3 && block.text.any? { |t| t.include?("docs/components/#{doc}.md") }
    end

    def trim(lines)
      lines.drop_while(&:empty?).reverse.drop_while(&:empty?).reverse
    end
  end
end
