# frozen_string_literal: true

require "test_helper"
require "generators/modelrails_ui/components"

class TestGeneratorsComponentsRegistry < Minitest::Test
  def test_supported_matches_template_directories
    template_dirs = Dir.children(ModelrailsUi::Generators::Components::TEMPLATE_ROOT).sort

    assert_equal template_dirs, ModelrailsUi::Generators::Components.supported
  end

  def test_primary_path_for_component
    assert_equal "app/components/ui/button_component.rb",
      ModelrailsUi::Generators::Components.primary_path("button")
  end

  def test_installed_detects_existing_file
    root = Dir.mktmpdir
    path = ModelrailsUi::Generators::Components.primary_path("button")
    full = File.join(root, path)
    FileUtils.mkdir_p(File.dirname(full))
    File.write(full, "# stub")

    assert ModelrailsUi::Generators::Components.installed?("button", root)
  ensure
    FileUtils.remove_entry(root)
  end
end
