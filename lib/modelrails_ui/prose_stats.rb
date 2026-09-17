# frozen_string_literal: true

require_relative "component_header"

module ModelrailsUi
  # The before/after numbers for the component-docs single-home migration.
  module ProseStats
    Row = Data.define(:label, :files, :lines, :comment_lines, :header_lines)
    PreviewRow = Data.define(:label, :files, :class_notes, :scenario_notes, :annotations)

    module_function

    def component_row(label, files)
      lines = comments = headers = 0
      files.each do |f|
        ls = File.readlines(f)
        lines += ls.size
        comments += ls.count { |l| l.match?(/\A\s*#/) }
        headers += ComponentHeader.locate(ls)&.length.to_i
      end
      Row.new(label: label, files: files.size, lines: lines, comment_lines: comments, header_lines: headers)
    end

    def preview_row(label, files)
      cls = scen = ann = 0
      files.each do |f|
        ls = File.readlines(f)
        i = ls.index { |l| l.match?(/\A\s*class\s+\S/) } || ls.size
        ls.each_with_index do |l, k|
          next unless l.match?(/\A\s*#/) && !l.include?("frozen_string_literal")

          if l.match?(/\A\s*#\s*@/) then ann += 1
          elsif k < i then cls += 1
          else scen += 1
          end
        end
      end
      PreviewRow.new(label: label, files: files.size, class_notes: cls, scenario_notes: scen, annotations: ann)
    end

    def table(rows)
      rows.map do |r|
        case r
        when Row
          pct = ->(n) { r.lines.zero? ? 0 : (100.0 * n / r.lines).round }
          format("%-28s files=%d lines=%d comment=%d (%d%%) header=%d (%d%%)",
            r.label, r.files, r.lines, r.comment_lines, pct.call(r.comment_lines), r.header_lines, pct.call(r.header_lines))
        when PreviewRow
          format("%-28s files=%d class_notes=%d scenario_notes=%d annotations=%d",
            r.label, r.files, r.class_notes, r.scenario_notes, r.annotations)
        end
      end.join("\n")
    end
  end
end
