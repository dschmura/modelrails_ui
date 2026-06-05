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

  def with_block(content)
    ModelrailsUi::Generators::AgentRulesGenerator
      .allocate.send(:with_import_block, content)
  end

  def test_adds_block_to_empty_file
    result = with_block("")
    assert_includes result, "<!-- BEGIN modelrails_ui -->"
    assert_includes result, "@.modelrails_ui/agent-rules.md"
  end

  def test_appends_block_after_existing_content_with_separation
    result = with_block("# My rules\n")
    assert_includes result, "# My rules"
    assert_includes result, "<!-- BEGIN modelrails_ui -->"
    assert result.index("# My rules") < result.index("<!-- BEGIN modelrails_ui -->")
  end

  def test_is_idempotent_when_block_already_present
    once = with_block("# My rules\n")
    twice = with_block(once)
    assert_equal once, twice
    assert_equal 1, twice.scan("<!-- BEGIN modelrails_ui -->").size
  end
end
