# frozen_string_literal: true

require "test_helper"
require "modelrails_ui/adoption"

class TestAdoptionReport < Minitest::Test
  APP = File.expand_path("fixtures/adoption_app", __dir__)

  def test_report_has_a_row_per_supported_component
    report = ModelrailsUi::Adoption.report(app_root: APP)

    assert_equal ModelrailsUi::Generators::Components.supported.length, report[:rows].length
  end

  def test_blind_spots_are_adopted_but_under_audited
    report = ModelrailsUi::Adoption.report(app_root: APP)
    report[:blind_spots].each do |row|
      refute_equal :none, row[:adopted][:value]
      assert_operator row[:audited][:n], :<, row[:audited][:m]
    end
  end

  def test_markdown_short_list_names_the_remedy_levers
    md = ModelrailsUi::Adoption.render_markdown(
      ModelrailsUi::Adoption.report(app_root: APP), verbose: false
    )

    assert_match(/adoption\.yml/, md)
    assert_match(/modelrails_ui:adoption:strict/, md)
  end

  def test_suppression_is_effective_and_selective
    # The fixture's adoption.yml suppresses `alert`. Both `alert` and `badge`
    # are otherwise-qualifying blind spots here — each classifies :direct (via
    # a real `ui :...` call in the fixture views) with 0 audit coverage (the
    # fixture ships no spec/system/ui). So this proves suppression is BOTH:
    #   - effective: the suppressed `alert` is dropped from blind_spots, AND
    #   - selective: the un-suppressed `badge`, identically situated, remains —
    #     suppression removes ONLY the named row, not everything.
    # Remove `.reject { suppress }` from Adoption.report and this fails on the
    # `alert` assertion (alert would re-appear as a blind spot).
    report = ModelrailsUi::Adoption.report(app_root: APP)
    blind_names = report[:blind_spots].map { |r| r[:component] }
    alert = report[:rows].find { |r| r[:component] == "alert" }
    badge = report[:rows].find { |r| r[:component] == "badge" }

    # Preconditions: both are adopted + under-audited, so absent suppression
    # both WOULD qualify — the test is only meaningful if this holds.
    assert_equal :direct, alert[:adopted][:value]
    assert_operator alert[:audited][:n], :<, alert[:audited][:m]
    assert_equal :direct, badge[:adopted][:value]
    assert_operator badge[:audited][:n], :<, badge[:audited][:m]

    refute_includes blind_names, "alert", "suppressed component must be dropped"
    assert_includes blind_names, "badge", "un-suppressed peer must remain"
  end
end
