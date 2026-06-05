# frozen_string_literal: true

module ModelrailsUi
  module Generators
    # Optional: teaches a coding agent to defer to the modelrails_ui design system.
    # Writes a gem-owned rules file (overwritten on re-run), seeds a developer-owned
    # house-rules file (once), adds a marker-delimited @-import to the host agent file
    # (idempotent), and reports — never rewrites — conflicting host directives.
    #
    #   rails g modelrails_ui:agent_rules
    class AgentRulesGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      AGENT_FILE_CANDIDATES = %w[CLAUDE.md AGENTS.md].freeze

      MARKER = "<!-- BEGIN modelrails_ui -->"

      IMPORT_BLOCK = <<~MARKDOWN
        <!-- BEGIN modelrails_ui -->
        When building or changing UI, follow the design-system rules in @.modelrails_ui/agent-rules.md
        <!-- END modelrails_ui -->
      MARKDOWN

      CONFLICT_PATTERNS = [
        {
          pattern: /ViewComponents only when reused/i,
          summary: '"ViewComponents only when reused"',
          message: "modelrails_ui's UI::* primitives ARE the shared library; this guideline " \
                   "governs new app-specific components, not the design-system primitives."
        }
      ].freeze

      class_option :file, type: :string, default: nil,
        desc: "Host agent file to import into (default: CLAUDE.md, else AGENTS.md)"

      def write_agent_rules
        # Gem-owned: always overwrite so re-running pulls the latest rules.
        copy_file "agent-rules.md", ".modelrails_ui/agent-rules.md", force: true
      end

      def seed_house_rules
        target = ".modelrails_ui/house-rules.md"
        if File.exist?(File.join(destination_root, target))
          say "  #{target} already exists — leaving your edits untouched.", :yellow
        else
          copy_file "house-rules.md", target
        end
      end

      def ensure_import
        target = agent_file
        path = File.join(destination_root, target)
        existing = File.exist?(path) ? File.read(path) : ""
        updated = with_import_block(existing)

        if updated == existing
          say "  #{target} already imports the design-system rules — skipping.", :yellow
        else
          create_file target, updated, force: true
          say "  Added the modelrails_ui import block to #{target}.", :green
        end
      end

      def report_conflicts
        warnings = scan_files.flat_map do |relpath|
          conflict_warnings(File.read(File.join(destination_root, relpath)), file: relpath)
        end
        return if warnings.empty?

        say "\n  Heads up — found directives that may conflict with the design system:", :yellow
        warnings.each do |w|
          say "    • #{w[:file]}: #{w[:summary]}", :yellow
          say "      Suggest: #{w[:message]}", :cyan
        end
        say "  (Not changed — edit them yourself if you agree.)\n", :yellow
      end

      def print_summary
        say "\n  Design-system agent rules installed.", :green
        say "    • .modelrails_ui/agent-rules.md  (gem-owned; re-run to update)", :cyan
        say "    • .modelrails_ui/house-rules.md   (yours to edit)", :cyan
        say "    • import added to #{agent_file}\n", :cyan
      end

      private

      # Pure: explicit override wins, else first existing candidate in priority
      # order (CLAUDE.md before AGENTS.md), else the default (CLAUDE.md).
      def pick_agent_file(existing:, override: nil)
        return override if override && !override.empty?

        (AGENT_FILE_CANDIDATES & existing).first || AGENT_FILE_CANDIDATES.first
      end

      # Pure: returns content unchanged if the block is already present; otherwise
      # appends it (with a blank-line separator when content is non-empty). Presence
      # is detected by the BEGIN marker alone, so a manually truncated block (END
      # deleted) is also treated as present — we never rewrite host files.
      def with_import_block(content)
        return content if content.include?(MARKER)

        content.empty? ? IMPORT_BLOCK : "#{content.chomp}\n\n#{IMPORT_BLOCK}"
      end

      # Pure: returns one warning hash per known-tension pattern found in `content`.
      def conflict_warnings(content, file:)
        CONFLICT_PATTERNS.filter_map do |c|
          next unless content.match?(c[:pattern])

          {file: file, summary: c[:summary], message: c[:message]}
        end
      end

      def agent_file
        @agent_file ||= pick_agent_file(
          existing: AGENT_FILE_CANDIDATES.select { |c| File.exist?(File.join(destination_root, c)) },
          override: options[:file]
        )
      end

      # Files worth scanning for conflicts: the resolved agent file (including a
      # custom --file target) + the conventional agent files + ClaudeOnRails context.
      def scan_files
        (AGENT_FILE_CANDIDATES + [".claude-on-rails/context.md", agent_file]).uniq
          .select { |f| File.exist?(File.join(destination_root, f)) }
      end
    end
  end
end
