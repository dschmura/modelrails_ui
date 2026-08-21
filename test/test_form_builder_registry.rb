# frozen_string_literal: true

require "test_helper"
require "generators/modelrails_ui/components"
require "rails/generators"
require_relative "../lib/generators/modelrails_ui/add/add_generator"

# form_builder is the first template whose Ruby file is NOT a ViewComponent.
# These tests pin the three registry facts that make that safe: routing
# (NON_COMPONENT_RB), truthful install status (PRIMARY_PATHS), and transitive
# installation of the components the builder references (DEPENDENCIES).
# Shape follows test_shared_js_modules.rb — the same defect class, one asset kind over.
class TestFormBuilderRegistry < Minitest::Test
  Components = ModelrailsUi::Generators::Components
  TEMPLATES = File.expand_path("../lib/generators/modelrails_ui/add/templates", __dir__)

  def test_non_component_rb_sources_exist_on_disk
    Components::NON_COMPONENT_RB.each_key do |source|
      assert_path_exists File.join(TEMPLATES, source),
        "NON_COMPONENT_RB names a template that is not on disk: #{source}"
    end
  end

  # The silent-misfile invariant: any .rb.tt that is not a *_component.rb.tt
  # must be claimed by NON_COMPONENT_RB, or the generator's fallback would
  # install it into app/components/ui/ where it does not belong.
  def test_every_non_component_rb_template_is_registered
    on_disk = Dir.glob("#{TEMPLATES}/*/*.rb.tt")
      .reject { |p| File.basename(p).end_with?("_component.rb.tt") }
      .map { |p| p.delete_prefix("#{TEMPLATES}/") }

    assert_equal on_disk.sort, (on_disk & Components::NON_COMPONENT_RB.keys).sort,
      "unregistered non-component .rb.tt would be misfiled into app/components/ui/: " \
      "#{(on_disk - Components::NON_COMPONENT_RB.keys).inspect}"
  end

  def test_primary_path_for_form_builder_points_at_app_form_builders
    assert_equal "app/form_builders/ui/form_builder.rb", Components.primary_path("form_builder")
  end

  def test_primary_path_for_ordinary_components_is_unchanged
    assert_equal "app/components/ui/button_component.rb", Components.primary_path("button")
  end

  def test_expand_resolves_form_builder_dependencies_transitively_without_duplicates
    expanded = Components.expand(%w[form_builder])

    assert_equal "form_builder", expanded.first
    %w[form_field input textarea file_input select label].each do |dep|
      assert_includes expanded, dep
    end
    assert_equal expanded.uniq, expanded
  end

  def test_expand_is_identity_for_components_without_dependencies
    assert_equal %w[button], Components.expand(%w[button])
  end

  def test_every_declared_dependency_is_a_supported_component
    Components::DEPENDENCIES.each_value do |deps|
      deps.each { |d| assert_includes Components.supported, d }
    end
  end

  def test_form_builder_has_a_setup_note_naming_default_form_builder
    assert_includes Components::SETUP_NOTES.fetch("form_builder"), "default_form_builder"
  end

  def generator = ModelrailsUi::Generators::AddGenerator.allocate

  def test_rb_tt_destination_honours_the_non_component_map
    assert_equal "app/form_builders/ui/form_builder.rb",
      generator.send(:rb_tt_destination, "form_builder", "form_builder.rb.tt")
  end

  def test_rb_tt_destination_defaults_to_app_components_ui
    assert_equal "app/components/ui/button_component.rb",
      generator.send(:rb_tt_destination, "button", "button_component.rb.tt")
  end
end
