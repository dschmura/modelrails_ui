# frozen_string_literal: true

require "test_helper"

# Per-preview `@display background <value>` tags (SPACE-separated — Lookbook's tag
# parser reads `background:` WITH a colon as the key name, which never matches) drive the preview-layout body background
# (raised default · sunken · surface · bleed). Guard the vocabulary and require the
# two tagged families to exist (raised containers + page chrome).
class TestLookbookDisplayBackgrounds < Minitest::Test
  GEN_ROOT = File.expand_path("../lib/generators/modelrails_ui/lookbook/templates", __dir__)
  PREVIEW_ROOT = File.join(GEN_ROOT, "previews/ui")
  LAYOUT = File.join(GEN_ROOT, "component_preview.html.erb")
  ALLOWED = %w[sunken surface bleed].freeze

  def tags
    Dir.glob(File.join(PREVIEW_ROOT, "*_component_preview.rb")).each_with_object({}) do |path, acc|
      value = File.read(path)[/^\s*#\s*@display background\s+(\S+)/, 1]
      acc[File.basename(path, "_component_preview.rb")] = value if value
    end
  end

  def test_background_values_are_in_vocabulary
    bad = tags.reject { |_c, v| ALLOWED.include?(v) }

    assert_empty bad, "unknown @display background values: #{bad.inspect} (allowed: #{ALLOWED.join(", ")})"
  end

  def test_tagged_families_exist
    refute_empty tags, "no @display background tags found"
    assert_includes tags.keys, "card", "card must opt into the sunken background"
    assert_includes tags.keys, "navbar", "navbar must opt into the bleed background"
  end

  def test_layout_consumes_the_background_param
    assert_match(/lookbook.*display.*background/m, File.read(LAYOUT),
      "component_preview layout must read params.dig(:lookbook, :display, :background)")
  end
end
