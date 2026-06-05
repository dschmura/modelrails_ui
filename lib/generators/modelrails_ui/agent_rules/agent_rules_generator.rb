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

      class_option :file, type: :string, default: nil,
        desc: "Host agent file to import into (default: CLAUDE.md, else AGENTS.md)"

      private

      # Pure: explicit override wins, else first existing candidate in priority
      # order (CLAUDE.md before AGENTS.md), else the default (CLAUDE.md).
      def pick_agent_file(existing:, override: nil)
        return override if override && !override.empty?

        (AGENT_FILE_CANDIDATES & existing).first || AGENT_FILE_CANDIDATES.first
      end
    end
  end
end
