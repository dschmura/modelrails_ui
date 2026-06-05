# frozen_string_literal: true

require "test_helper"
require "rails/generators"
require_relative "../lib/generators/modelrails_ui/agent_rules/agent_rules_generator"

class TestAgentRulesGenerator < Minitest::Test
  TEMPLATE_ROOT = File.expand_path(
    "../lib/generators/modelrails_ui/agent_rules/templates", __dir__
  )

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
    assert_operator result.index("# My rules"), :<, result.index("<!-- BEGIN modelrails_ui -->")
  end

  def test_is_idempotent_when_block_already_present
    once = with_block("# My rules\n")
    twice = with_block(once)

    assert_equal once, twice
    assert_equal 1, twice.scan("<!-- BEGIN modelrails_ui -->").size
  end

  def test_does_not_re_add_when_only_begin_marker_present
    content = "<!-- BEGIN modelrails_ui -->\n"

    assert_equal content, with_block(content)
  end

  def warnings_for(content)
    ModelrailsUi::Generators::AgentRulesGenerator
      .allocate.send(:conflict_warnings, content, file: "context.md")
  end

  def test_flags_viewcomponents_only_when_reused
    warnings = warnings_for("- ViewComponents only when reused across unrelated views")

    assert_equal 1, warnings.size
    assert_equal "context.md", warnings.first[:file]
    assert_includes warnings.first[:message], "shared library"
  end

  def test_no_warnings_for_clean_content
    assert_empty warnings_for("- Use Pundit for authorization")
  end

  def test_agent_rules_template_anchors_present
    content = File.read(File.join(TEMPLATE_ROOT, "agent-rules.md"))

    assert_includes content, "Design system rules (modelrails_ui)"
    assert_includes content, "bin/rails g modelrails_ui:list"
    assert_includes content, "text-text-muted"
    assert_includes content, "@.modelrails_ui/house-rules.md"
  end

  def test_house_rules_template_anchors_present
    content = File.read(File.join(TEMPLATE_ROOT, "house-rules.md"))

    assert_includes content, "I18n locale keys"
    assert_includes content, "Stimulus"
  end
end
