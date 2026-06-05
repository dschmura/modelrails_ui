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

      private

      # Pure: explicit override wins, else first existing candidate in priority
      # order (CLAUDE.md before AGENTS.md), else the default (CLAUDE.md).
      def pick_agent_file(existing:, override: nil)
        return override if override && !override.empty?

        (AGENT_FILE_CANDIDATES & existing).first || AGENT_FILE_CANDIDATES.first
      end

      # Pure: returns content unchanged if the block is already present; otherwise
      # appends it (with a blank-line separator when content is non-empty).
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
    end
  end
end
