# frozen_string_literal: true

require "test_helper"

# Every preview that has META scenarios (showcase / playground / dont_*) must group its
# scenarios into Overview/Examples/Reference in the canonical order. Canonical-only previews
# (no meta) are exempt and stay flat. Guards against scenario-order drift going forward.
class TestLookbookScenarioGrouping < Minitest::Test
  PREVIEW_ROOT = File.expand_path(
    "../lib/generators/modelrails_ui/lookbook/templates/previews/ui", __dir__
  )

  RANK = {overview: 0, examples: 1, reference_pg: 2, reference_dont: 3}.freeze

  def classify(name)
    return :overview if name == "showcase"
    return :reference_pg if name == "playground"
    return :reference_dont if name.start_with?("dont_")
    :examples
  end

  def scenario_methods(src)
    src.scan(/^\s+def ([a-z_][a-z0-9_]*)/).flatten - %w[input_attrs]
  end

  def group_labels(src)
    src.scan(/^\s*#\s*@!group\s+(\w+)/).flatten
  end

  def previews
    Dir.glob(File.join(PREVIEW_ROOT, "*_component_preview.rb"))
  end

  def test_grouped_previews_are_in_canonical_order
    previews.each do |path|
      component = File.basename(path, "_component_preview.rb")
      src = File.read(path)
      methods = scenario_methods(src)
      has_meta = methods.any? { |m| m == "showcase" || m == "playground" || m.start_with?("dont_") }
      next unless has_meta

      ranks = methods.map { |m| RANK.fetch(classify(m)) }

      assert_equal ranks.sort, ranks,
        "#{component}: scenarios out of canonical order (showcase→examples→playground→dont): #{methods.inspect}"

      expected = []
      expected << "Overview" if methods.include?("showcase")
      expected << "Examples"
      expected << "Reference"

      assert_equal expected, group_labels(src),
        "#{component}: @!group labels #{group_labels(src).inspect} != expected #{expected.inspect}"
    end
  end

  def test_canonical_only_previews_stay_flat
    previews.each do |path|
      component = File.basename(path, "_component_preview.rb")
      src = File.read(path)
      methods = scenario_methods(src)
      has_meta = methods.any? { |m| m == "showcase" || m == "playground" || m.start_with?("dont_") }
      next if has_meta

      assert_empty group_labels(src),
        "#{component}: canonical-only preview should stay flat (no @!group), got #{group_labels(src).inspect}"
    end
  end
end
