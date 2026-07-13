# frozen_string_literal: true

require "test_helper"
require "modelrails_ui/adoption/audit_coverage"

class TestAdoptionAuditCoverage < Minitest::Test
  SPECS = File.expand_path("fixtures/adoption_specs", __dir__)
  PREVIEWS = File.expand_path("fixtures/adoption_previews", __dir__)

  def cov
    @cov ||= ModelrailsUi::Adoption::AuditCoverage.new(specs_root: SPECS, previews_root: PREVIEWS)
  end

  def test_literal_visits_are_counted
    assert_equal({n: 2, m: 2, unresolved: 0}, cov.cover("lit"))
  end

  def test_loop_driven_interpolation_expands_to_full_coverage
    # #{scenario} over %w[default info success] must be 3/3, not 1/3.
    assert_equal({n: 3, m: 3, unresolved: 0}, cov.cover("loop"))
  end

  def test_constant_base_path_associates_scenarios_with_the_component
    # PREVIEW constant resolution -> off/on counted, not 0/2.
    assert_equal({n: 2, m: 2, unresolved: 0}, cov.cover("const"))
  end

  def test_default_only_component_is_full_coverage
    assert_equal({n: 1, m: 1, unresolved: 0}, cov.cover("solo"))
  end

  def test_genuinely_unresolvable_interpolation_is_flagged_not_dropped
    result = cov.cover("unresolved")

    assert_equal 0, result[:n]
    assert_equal 1, result[:m]
    assert_equal 1, result[:unresolved],
      "an unresolvable visit must increment unresolved, never be silently dropped"
  end

  # Beyond-brief coverage: real-world shapes discovered while auditing
  # modelrails_base's actual 0b system specs (range/alert/badge component
  # specs). See audit_coverage.rb's class comment for why these matter.
  def test_chained_bare_constant_is_resolved
    assert_equal({n: 1, m: 1, unresolved: 0}, cov.cover("chain"))
  end

  def test_string_keyed_hash_loop_expands_to_full_coverage
    assert_equal({n: 2, m: 2, unresolved: 0}, cov.cover("hashloop"))
  end
end
