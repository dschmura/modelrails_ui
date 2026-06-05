# frozen_string_literal: true

require "test_helper"
require "rails/generators"
require_relative "../lib/generators/modelrails_ui/agent_rules/agent_rules_generator"

class TestAgentRulesGenerator < Minitest::Test
  # `pick_agent_file` is pure (no destination_root / FS), so allocate skips #initialize.
  def pick(existing:, override: nil)
    ModelrailsUi::Generators::AgentRulesGenerator
      .allocate.send(:pick_agent_file, existing: existing, override: override)
  end

  def test_prefers_claude_md_when_it_exists
    assert_equal "CLAUDE.md", pick(existing: ["CLAUDE.md", "AGENTS.md"])
  end

  def test_falls_back_to_agents_md_when_only_it_exists
    assert_equal "AGENTS.md", pick(existing: ["AGENTS.md"])
  end

  def test_defaults_to_claude_md_when_neither_exists
    assert_equal "CLAUDE.md", pick(existing: [])
  end

  def test_explicit_override_wins
    assert_equal "docs/AGENT.md", pick(existing: ["CLAUDE.md"], override: "docs/AGENT.md")
  end
end
