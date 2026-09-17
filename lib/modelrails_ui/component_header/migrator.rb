# frozen_string_literal: true

require_relative "../component_header"

module ModelrailsUi
  module ComponentHeader
    # Moves a header's sections into the component's markdown doc and replaces
    # the header with the three-line pointer. Pure functions over strings; the
    # bin script owns file I/O.
    module Migrator
      HEADING_MAP = {
        "use when" => "When to use",
        "don't use when" => "When not to use",
        "accessibility contract" => "Accessibility contract",
        "parameters" => "Parameters"
      }.freeze

      module_function

      # Returns [new_source_lines, new_doc_text]. Idempotent: a source already
      # carrying the pointer is returned unchanged with the doc untouched.
      def migrate(component, source_lines, doc_text)
        doc = ComponentHeader.doc_name(component)
        block = ComponentHeader.locate(source_lines)
        return [source_lines, doc_text] if ComponentHeader.pointer?(block, doc: doc)

        if block
          intro, sections = ComponentHeader.sections(block)
          summary = ComponentHeader.summary(intro)
          summary = doc_summary(doc_text) if summary.empty?
          new_doc = sections.reduce(doc_text) do |text, s|
            append_section(text, map_heading(s.heading, component: component, doc: doc), s.lines)
          end
          new_source = source_lines.dup
          new_source[block.start, block.length] = comment_lines(ComponentHeader.pointer(summary: summary, doc: doc), block.indent)
        else
          i = source_lines.index { |l| l.match?(/\A\s*class\s+\S/) }
          indent = source_lines[i][/\A\s*/]
          new_doc = doc_text
          new_source = source_lines.dup
          new_source.insert(i, *comment_lines(ComponentHeader.pointer(summary: doc_summary(doc_text), doc: doc), indent))
        end
        [new_source, new_doc]
      end

      def map_heading(heading, component:, doc:)
        suffix = heading[/\s*\(.*\)\z/].to_s
        key = heading.downcase.sub(/\s*\(.*\)\z/, "").strip
        mapped = HEADING_MAP.fetch(key, heading.sub(/\s*\(.*\)\z/, "").strip) + suffix
        (component == doc) ? mapped : "#{component.tr("_", " ").capitalize}: #{mapped}"
      end

      # Appends `lines` under `## heading`, reusing an existing heading of the
      # same name instead of adding a second one.
      def append_section(doc_text, heading, lines)
        body = lines.join("\n")
        existing = doc_text.match(/^## #{Regexp.escape(heading)}[ \t]*$/i)
        if existing
          next_heading = doc_text.index(/^## /, existing.end(0)) || doc_text.size
          "#{doc_text[0...next_heading].rstrip}\n\n#{body}\n\n#{doc_text[next_heading..]}"
        else
          "#{doc_text.rstrip}\n\n## #{heading}\n\n#{body}\n"
        end
      end

      # Section headings whose doc coverage is incomplete — every substantive
      # (>=25 char) section line must be ComponentHeader.stated_in? the doc,
      # and every intro sentence after the summary (the first) must too —
      # the check --rewrite-only relies on so nothing is dropped silently.
      # The 25-char floor matches bin/header-fidelity's own filter (and the
      # intro branch's, below) so the tripwire and the audit judge the same
      # line set — a hard-wrapped tail too short to shingle (e.g.
      # "controller.") is never substantive enough to flag on its own. A
      # fact the doc restates as prose, a bullet, or folds into a table row
      # still counts as covered. The literal string "intro" is included
      # alongside headings when an intro sentence is missing.
      def missing_from_doc(block, doc_text)
        intro, sections = ComponentHeader.sections(block)
        missing = sections.select { |s| s.lines.any? { |l| l.strip.length >= 25 && !ComponentHeader.stated_in?(l.strip, doc_text) } }
          .map(&:heading)

        sentences = intro.join(" ").split(/(?<=[.!?])\s+/).map(&:strip).reject(&:empty?)
        rest = sentences.drop(1).reject { |s| s.length < 25 }
        missing << "intro" if rest.any? { |s| !ComponentHeader.stated_in?(s, doc_text) }

        missing
      end

      def comment_lines(text_lines, indent)
        text_lines.map { |l| "#{indent}# #{l}".rstrip + "\n" }
      end

      def doc_summary(doc_text)
        para = doc_text.lines.map(&:rstrip).drop_while { |l| l.start_with?("#") || l.empty? }.take_while { |l| !l.empty? }.join(" ")
        para[/\A.*?[.!?](?=\s|\z)/] || para
      end
    end
  end
end
