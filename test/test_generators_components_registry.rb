# frozen_string_literal: true

require "test_helper"
require "generators/view_primitives/components"

class TestGeneratorsComponentsRegistry < Minitest::Test
  def test_supported_matches_template_directories
    template_dirs = Dir.children(ViewPrimitives::Generators::Components::TEMPLATE_ROOT).sort

    assert_equal template_dirs, ViewPrimitives::Generators::Components.supported
  end

  def test_primary_path_for_component
    assert_equal "app/components/ui/button_component.rb",
      ViewPrimitives::Generators::Components.primary_path("button")
  end

  def test_installed_detects_existing_file
    root = Dir.mktmpdir
    path = ViewPrimitives::Generators::Components.primary_path("button")
    full = File.join(root, path)
    FileUtils.mkdir_p(File.dirname(full))
    File.write(full, "# stub")

    assert ViewPrimitives::Generators::Components.installed?("button", root)
  ensure
    FileUtils.remove_entry(root)
  end
end
