# frozen_string_literal: true

require "test_helper"

# The Overview landing page must exist, teach the core conventions, and embed only
# scenarios that actually exist (a broken embed target would 500 the page at runtime).
class TestLookbookOverviewPage < Minitest::Test
  GEN_ROOT = File.expand_path("../lib/generators/modelrails_ui/lookbook/templates", __dir__)
  PAGE = File.join(GEN_ROOT, "previews/pages/00_overview.md.erb")
  PREVIEW_ROOT = File.join(GEN_ROOT, "previews/ui")
  INITIALIZER = File.join(GEN_ROOT, "lookbook.rb")

  SECTIONS = [
    "Forms & Inputs", "Actions", "Overlays", "Navigation",
    "Feedback & Status", "Data Display", "Media", "Layout"
  ].freeze

  def page_src
    File.read(PAGE)
  end

  def test_page_exists_and_sorts_first
    assert_path_exists PAGE, "Overview page must exist at previews/pages/00_overview.md.erb"
    assert_match(/label:\s*Overview/, page_src, "page needs a front-matter `label: Overview`")
  end

  def test_page_teaches_core_conventions
    assert_includes page_src, "ui :button", "page must show the ui() facade call"
    assert_includes page_src, "f.submit", "page must teach 'reach for the Rails built-in first'"
    SECTIONS.each do |section|
      assert_includes page_src, section, "page BROWSE index must list the `#{section}` section"
    end
  end

  def test_every_embed_target_exists
    embeds = page_src.scan(/embed\s+UI::(\w+)ComponentPreview,\s*:(\w+)/)

    assert_operator embeds.size, :>=, 3, "page should embed at least 3 live hero scenarios"
    embeds.each do |klass, scenario|
      file = File.join(PREVIEW_ROOT, "#{klass.gsub(/([a-z])([A-Z])/, '\1_\2').downcase}_component_preview.rb")

      assert_path_exists file, "embed references missing preview #{klass}"
      assert_match(/def #{scenario}\b/, File.read(file), "embed references missing scenario :#{scenario} on #{klass}")
    end
  end

  def test_initializer_wires_page_paths
    assert_match(/page_paths\s*=/, File.read(INITIALIZER), "lookbook.rb must set config.lookbook.page_paths")
  end
end
