# frozen_string_literal: true

require "test_helper"
require "generators/modelrails_ui/components"
require "modelrails_ui/adoption/scenarios"

# Inventory-derived, content-asserting completeness gate: every shipped
# component (all 81 Components.supported dirs) must have a real Lookbook
# preview and a real render test — not an empty stub. Replaces the
# hand-maintained PRIMITIVES allow-list (which used assert_path_exists, so
# an empty .erb passed). Exemptions require a machine-checkable supersede
# signal, never a free-text comment.
class TestCatalogCompleteness < Minitest::Test
  Components = ModelrailsUi::Generators::Components
  PREVIEWS_ROOT = File.expand_path(
    "../lib/generators/modelrails_ui/lookbook/templates/previews/ui", __dir__
  )
  RENDER_TEST_ROOT = File.expand_path("render", __dir__)

  # Components exempt from the gate — ONLY superseded primitives the host is
  # not expected to adopt. Each entry needs a real supersede reason; the gate
  # itself does not currently ship a `superseded:` marker file, so this list
  # is the single, reviewed, in-code source. Adding a non-superseded component
  # here is a review-blocking smell.
  SUPERSEDED_EXEMPT = {}.freeze # pagination is NOT here — it must be fixed, not exempted

  # Components exempt because they ship no `UI::*Component` class at all —
  # partial-only generator output, so there is nothing to preview or
  # render_inline in the catalog. Distinct from SUPERSEDED_EXEMPT (which is
  # for components that DO have a class but are deliberately not promoted).
  PARTIAL_ONLY = %w[form_draft].freeze

  # Components exempt from ONE check inside the render-test predicate below:
  # the `render_inline` literal-match heuristic. form_builder ships
  # `UI::FormBuilder < ActionView::Helpers::FormBuilder`, not a ViewComponent
  # — its render test (test/render/form_builder_render_test.rb) calls the
  # builder's Rails-named field methods directly and asserts on the returned
  # HTML via Capybara, so it never calls ViewComponent::TestCase's
  # `render_inline`, even though every field method it exercises renders
  # real UI::* components internally through the current view context. The
  # has_method/has_assert checks still apply in full — this only widens
  # what counts as "really rendering". Distinct from PARTIAL_ONLY, which
  # drops a component out of the gate entirely (including the preview
  # check, which form_builder does NOT get here — that failure stays red
  # until Task 8 ships its preview).
  NOT_A_VIEWCOMPONENT = %w[form_builder].freeze

  def gated_components
    Components.supported - SUPERSEDED_EXEMPT.keys - PARTIAL_ONLY
  end

  def test_every_component_has_at_least_one_auditable_preview_scenario
    missing = gated_components.reject do |c|
      ModelrailsUi::Adoption::Scenarios.for(c, previews_root: PREVIEWS_ROOT).any?
    end

    assert_empty missing, "components with no auditable preview scenario: #{missing.join(", ")}"
  end

  def test_every_preview_scenario_template_is_non_empty_and_references_its_component
    offenders = []
    gated_components.each do |c|
      dir = File.join(PREVIEWS_ROOT, "#{c}_component_preview")
      ModelrailsUi::Adoption::Scenarios.for(c, previews_root: PREVIEWS_ROOT).each do |scenario|
        src = File.read(File.join(dir, "#{scenario}.html.erb"))
        klass = "UI::#{c.split("_").map(&:capitalize).join}Component"
        stripped = src.gsub(/<%#.*?%>/m, "") # ignore comment-only content
        ok = stripped.strip.length.positive? &&
          (stripped.include?("ui :#{c}") || stripped.include?("ui(:#{c}") ||
           stripped.include?(klass) || stripped.include?("<%="))
        offenders << "#{c}##{scenario}" unless ok
      end
    end

    assert_empty offenders, "empty/component-less preview templates: #{offenders.join(", ")}"
  end

  def test_every_component_has_a_content_asserting_render_test
    offenders = []
    gated_components.each do |c|
      path = File.join(RENDER_TEST_ROOT, "#{c}_render_test.rb")
      unless File.exist?(path)
        offenders << "#{c} (no render test)"
        next
      end
      src = File.read(path)
      has_method = src.match?(/def test_\w+/)
      has_render = NOT_A_VIEWCOMPONENT.include?(c) || src.include?("render_inline")
      has_assert = src.match?(/\bassert|\brefute/)
      offenders << "#{c} (stub render test)" unless has_method && has_render && has_assert
    end

    assert_empty offenders, "components missing a real render test: #{offenders.join(", ")}"
  end
end
