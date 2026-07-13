# frozen_string_literal: true

require "test_helper"
require "modelrails_ui/adoption/scenarios"

class TestAdoptionScenarios < Minitest::Test
  ROOT = File.expand_path(
    "../lib/generators/modelrails_ui/lookbook/templates/previews/ui", __dir__
  )

  def test_lists_auditable_scenarios_excluding_dont_examples
    scenarios = ModelrailsUi::Adoption::Scenarios.for("alert", previews_root: ROOT)

    assert_includes scenarios, "default"
    assert_includes scenarios, "showcase"
    refute_includes scenarios, "dont_empty", "anti-pattern examples are not auditable states"
    assert_equal scenarios.sort, scenarios, "returns sorted for stable M"
  end

  def test_returns_empty_when_no_preview_dir
    assert_empty ModelrailsUi::Adoption::Scenarios.for("nonexistent_component", previews_root: ROOT)
  end
end
