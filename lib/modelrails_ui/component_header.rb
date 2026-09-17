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

    # The fixed prefix of a migrated pointer's second line — the one string every
    # pointer carries regardless of doc name. `pointer` builds line 2 from it;
    # `locate` looks for it to recognize an already-migrated header.
    POINTER_MARKER = "Usage, options and the accessibility contract: docs/components/"

    # Plain-text section headings some hand-written headers used instead of the
    # markdown `## Heading` form (e.g. `Accessibility contract:` with no `##`) —
    # `sections` treats these the same as their markdown equivalent.
    COLON_HEADING = /\A(Use when|Don't use when|Accessibility contract|Parameters|Keyboard):?\z/i

    module_function

    def doc_name(component) = DOC_PARENT.fetch(component, component)

    # Returns a Block, or nil when the file has no class-level comment.
    def locate(lines)
      i = lines.index { |l| l.match?(/\A\s*class\s+\S/) } or return nil

      mod_idx = lines[0...i].rindex { |l| l.match?(/\A\s*module\s+\S/) }
      region_start = mod_idx ? mod_idx + 1 : 0

      # A header can be severed from the class line by constants or blank lines
      # in between (e.g. card_title's title-led header, then LEVELS/DEFAULT_LEVEL,
      # then the class). Search the whole module-to-class region first: an
      # already-migrated pointer always wins outright, and a title-led (markdown
      # H1) header wins over any other comment block in the region — both can
      # otherwise lose a naive adjacent-block size comparison.
      blocks = comment_blocks(lines, region_start, i)
      marked = blocks.find { |r| lines[r].any? { |l| l.include?(POINTER_MARKER) } } ||
        blocks.find { |r| lines[r].first.match?(/\A\s*#\s*#\s+\S/) }
      if marked
        seg = lines[marked]
        return Block.new(start: marked.begin, length: seg.size, lines: seg, position: :above, indent: seg.first[/\A\s*/])
      end

      up_start = i
      up_start -= 1 while up_start.positive? && lines[up_start - 1].match?(/\A\s*#/)
      up = lines[up_start...i]
      up = [] if up.any? { |l| l.include?("frozen_string_literal") }

      down_end = i + 1
      down_end += 1 while down_end < lines.size && lines[down_end].match?(/\A\s*#/)
      down = lines[(i + 1)...down_end]

      if up.size >= down.size
        return nil if up.empty?

        Block.new(start: up_start, length: up.size, lines: up, position: :above, indent: up.first[/\A\s*/])
      else
        Block.new(start: i + 1, length: down.size, lines: down, position: :below, indent: down.first[/\A\s*/])
      end
    end

    # Contiguous `#` runs within lines[from...to], as Ranges — excludes any run
    # that carries the magic comment (never a real header).
    def comment_blocks(lines, from, to)
      ranges = []
      start = nil
      (from...to).each do |idx|
        if lines[idx].match?(/\A\s*#/)
          start ||= idx
        elsif start
          ranges << (start...idx)
          start = nil
        end
      end
      ranges << (start...to) if start
      ranges.reject { |r| lines[r].any? { |l| l.include?("frozen_string_literal") } }
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
        if (m = line.match(/\A##\s+(.+)\z/) || line.match(COLON_HEADING))
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

    # First sentence of the intro's first paragraph. A `.` doesn't end the
    # sentence when it's followed by a space and a lowercase letter (`e.g. foo`,
    # `etc. and`, `i.e. bar`) — only `!`/`?`, or a `.` followed by whitespace-or-end
    # with no lowercase letter after, count as the terminator.
    def summary(intro)
      para = intro.drop_while(&:empty?).take_while { |l| !l.empty? }.join(" ")
      para[/\A.*?(?:[!?](?=\s|\z)|\.(?=\s|\z)(?!\s[a-z]))/] || para
    end

    # The three-line header every component carries after migration.
    def pointer(summary:, doc:)
      [
        summary,
        "#{POINTER_MARKER}#{doc}.md in the",
        "modelrails_ui gem (`bundle show modelrails_ui`); live examples in Lookbook."
      ]
    end

    def pointer?(block, doc:)
      !block.nil? && block.length == 3 && block.text.any? { |t| t.include?("docs/components/#{doc}.md") }
    end

    # True when `line`'s facts are covered by `corpus` — not necessarily
    # verbatim: both are normalized (backtick/`*`/`_`/`#`/`|`/`[`/`]`/`(`/`)`
    # to spaces, whitespace collapsed, downcased) and split into four-word
    # shingles (a line under four words is one shingle: the whole normalized
    # line). True when at least half of `line`'s shingles are also among
    # `corpus`'s shingles — so a fact restated as prose, a bullet, or folded
    # into a table row still counts. The same rule `bin/header-fidelity`
    # uses, shared here so both tools agree on what "stated in the doc"
    # means.
    def stated_in?(line, corpus)
      shingles = shingles_of(line)
      corpus_shingles = shingles_of(corpus)
      shingles.count { |sh| corpus_shingles.include?(sh) } >= (shingles.size * 0.5).ceil
    end

    # Four-word sliding-window phrases of `text`, normalized first (see
    # `stated_in?`) — a line under four words is one shingle: the whole line.
    def shingles_of(text)
      normalize = ->(s) { s.gsub(/[`*_#|\[\]()]/, " ").gsub(/\s+/, " ").strip.downcase }
      words = normalize.call(text).split(" ")
      (words.size < 4) ? [normalize.call(text)] : (0..words.size - 4).map { |i| words[i, 4].join(" ") }
    end

    def trim(lines)
      lines.drop_while(&:empty?).reverse.drop_while(&:empty?).reverse
    end
  end
end
