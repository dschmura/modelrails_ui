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

  # form_draft ships no component class — its primary file is the view partial.
  # Without a PRIMARY_PATHS entry, installed? falls back to a
  # form_draft_component.rb that never exists and `modelrails_ui:list`
  # misreports the component as not installed (#75).
  def test_installed_detects_a_partial_only_component_by_its_partial
    root = Dir.mktmpdir
    full = File.join(root, "app/views/shared/_form_draft_notice.html.erb")
    FileUtils.mkdir_p(File.dirname(full))
    File.write(full, "<%# stub %>")

    assert ModelrailsUi::Generators::Components.installed?("form_draft", root)
  ensure
    FileUtils.remove_entry(root)
  end

  # The inverse guard: every supported component's primary path must be a file
  # the add generator actually creates — a component whose primary file can
  # never exist is permanently "not installed" to `modelrails_ui:list`.
  def test_every_primary_path_is_producible_from_a_shipped_template
    templates = ModelrailsUi::Generators::Components::TEMPLATE_ROOT
    ModelrailsUi::Generators::Components.supported.each do |component|
      primary = File.basename(ModelrailsUi::Generators::Components.primary_path(component))
      sources = Dir.children(File.join(templates, component))
        .map { |f| f.delete_suffix(".tt") }

      assert_includes sources, primary,
        "#{component}: primary_path names #{primary}, but the template dir ships #{sources.inspect}"
    end
  end
end
