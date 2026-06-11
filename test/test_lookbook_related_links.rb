# frozen_string_literal: true

require "test_helper"

# `## Related` doc-comment sections encode the sibling-relationship graph. Every
# backticked name inside one must be a real component preview — typo/drift protection,
# same static-analysis idiom as the other lookbook guards.
class TestLookbookRelatedLinks < Minitest::Test
  PREVIEW_ROOT = File.expand_path(
    "../lib/generators/modelrails_ui/lookbook/templates/previews/ui", __dir__
  )

  def test_every_related_target_is_a_real_component
    names = Dir.glob(File.join(PREVIEW_ROOT, "*_component_preview.rb"))
      .map { |p| File.basename(p, "_component_preview.rb") }
    found_any = false

    Dir.glob(File.join(PREVIEW_ROOT, "*_component_preview.rb")).sort.each do |path|
      component = File.basename(path, "_component_preview.rb")
      lines = File.read(path).lines
      idx = lines.index { |l| l.match?(/^\s*#\s*## Related\s*$/) }
      next unless idx

      found_any = true
      block = lines[(idx + 1)..].take_while { |l| l.match?(/^\s*#/) && !l.match?(/^\s*#\s*(##|@)/) }.join
      targets = block.scan(/`([a-z_]+)`/).flatten.uniq

      refute_empty targets, "#{component}: empty ## Related section"
      missing = targets - names

      assert_empty missing, "#{component}: Related references unknown component(s): #{missing.join(", ")}"
    end

    assert found_any, "no ## Related sections found — the cross-link graph is missing"
  end
end
