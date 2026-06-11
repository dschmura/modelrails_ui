# frozen_string_literal: true

require "test_helper"

# The "choosing" decision pages must exist for every section with real sibling overlap,
# route every sibling in their section, and embed only in the scenario-less form (a
# `embed Klass, :leaf` resolves nil under the catalog-wide @!group grouping and 500s).
class TestLookbookChoosingPages < Minitest::Test
  GEN_ROOT = File.expand_path("../lib/generators/modelrails_ui/lookbook/templates", __dir__)
  PAGES_ROOT = File.join(GEN_ROOT, "previews/pages")
  PREVIEW_ROOT = File.join(GEN_ROOT, "previews/ui")

  # Layout and Actions get no decision page by design (too little sibling overlap).
  SECTION_BY_PAGE = {
    "choosing/00_forms.md.erb" => "Forms & Inputs",
    "choosing/01_overlays.md.erb" => "Overlays",
    "choosing/02_navigation.md.erb" => "Navigation",
    "choosing/03_feedback.md.erb" => "Feedback & Status",
    "choosing/04_data_display.md.erb" => "Data Display",
    "choosing/05_media.md.erb" => "Media"
  }.freeze

  def test_no_unmapped_choosing_pages
    actual = Dir.glob(File.join(PAGES_ROOT, "choosing/*.md.erb")).map { |p| p.sub("#{PAGES_ROOT}/", "") }.sort

    assert_equal SECTION_BY_PAGE.keys.sort, actual
  end

  def test_embeds_use_the_scenario_less_form
    Dir.glob(File.join(PAGES_ROOT, "**/*.md.erb")).sort.each do |page|
      offenders = File.read(page).scan(/embed\s+UI::\w+ComponentPreview\s*,\s*:\w+/)

      assert_empty offenders, "#{page}: use the scenario-less embed form"
    end
  end

  def test_every_embed_target_exists
    Dir.glob(File.join(PAGES_ROOT, "choosing/*.md.erb")).sort.each do |page|
      File.read(page).scan(/embed\s+UI::(\w+)ComponentPreview\b/).flatten.each do |klass|
        file = File.join(PREVIEW_ROOT, "#{klass.gsub(/([a-z])([A-Z])/, '\1_\2').downcase}_component_preview.rb")

        assert_path_exists file, "#{page} embeds missing preview #{klass}"
      end
    end
  end

  def test_every_section_sibling_is_routed
    SECTION_BY_PAGE.each do |rel, section|
      page = File.join(PAGES_ROOT, rel)

      assert_path_exists page
      source = File.read(page)
      siblings = Dir.glob(File.join(PREVIEW_ROOT, "*_component_preview.rb")).select do |path|
        File.read(path).match?(/^\s*#\s*@logical_path\s+#{Regexp.escape(section)}\s*$/)
      end.map { |path| File.basename(path, "_component_preview.rb") }.sort

      refute_empty siblings, "#{section}: no previews carry this @logical_path"
      # Backtick-delimited match so `dialog` is not falsely covered by `alert_dialog`.
      missing = siblings.reject { |name| source.match?(/`#{Regexp.escape(name)}`/) }

      assert_empty missing, "#{rel} is missing: #{missing.join(", ")}"
    end
  end
end
