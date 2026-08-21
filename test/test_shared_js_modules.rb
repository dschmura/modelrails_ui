# frozen_string_literal: true

require "test_helper"
require "rails/generators"
require_relative "../lib/generators/modelrails_ui/add/add_generator"

# Shared ES modules are the third kind of JS a component can ship, alongside its own
# Stimulus controller and one reused via EXTRA_STIMULUS. They exist because some behaviour
# has to be a SINGLE instance across every component that uses it (a layer stack, a top-layer
# helper), which a per-component controller copy cannot provide.
#
# The generator used to route only `*.rb.tt`, `*.html.erb` and `*_controller.js`; a plain
# `.js` file in a template directory was dropped with no warning, and the host importmap
# never learned about it. These tests pin both halves of the fix.
class TestSharedJsModules < Minitest::Test
  TEMPLATES = File.expand_path("../lib/generators/modelrails_ui/add/templates", __dir__)

  def generator = ModelrailsUi::Generators::AddGenerator.allocate

  # The invariant that makes a silent drop impossible: every plain `.js` sitting in a
  # template directory must be claimed by SHARED_JS, or the generator would ignore it.
  def test_every_plain_js_template_is_registered_as_a_shared_module
    registered = ModelrailsUi::Generators::Components::SHARED_JS.values.flatten
      .map { |m| m.fetch(:source) }.uniq

    on_disk = Dir.glob("#{TEMPLATES}/*/*.js")
      .reject { |p| p.end_with?("_controller.js") }
      .map { |p| p.delete_prefix("#{TEMPLATES}/") }

    assert_equal on_disk.sort, (on_disk & registered).sort,
      "unregistered shared modules would be silently dropped: #{(on_disk - registered).inspect}"
  end

  def test_registered_shared_module_sources_exist_on_disk
    ModelrailsUi::Generators::Components::SHARED_JS.each do |component, modules|
      modules.each do |mod|
        assert_path_exists File.join(TEMPLATES, mod.fetch(:source)),
          "#{component} declares a shared module that is not in templates/"
      end
    end
  end

  # Every component whose controller imports a shared module must declare it, or the
  # generated app raises on a bare-module import that nothing pinned.
  def test_components_importing_a_shared_module_declare_it
    missing = Dir.glob("#{TEMPLATES}/*/*_controller.js").filter_map do |path|
      imported = File.read(path).scan(/from\s+"([a-z_]+\/[a-z_]+)"/).flatten
      next if imported.empty?

      component = File.basename(File.dirname(path))
      declared = shared_dirs_for(component)
      unmet = imported.reject { |ref| declared.include?(ref.split("/").first) }
      [component, unmet] if unmet.any?
    end

    assert_empty missing, "controllers import shared modules their component does not declare: #{missing.inspect}"
  end

  def test_shared_module_destination_is_namespaced_under_app_javascript
    mod = {source: "dropdown_menu/top_layer.js", dir: "overlays"}

    assert_equal "app/javascript/overlays/top_layer.js",
      generator.send(:shared_js_destination, mod)
  end

  def test_pin_line_matches_the_namespace_directory
    assert_equal %(pin_all_from "app/javascript/overlays", under: "overlays"),
      generator.send(:shared_js_pin, "overlays")
  end

  private

  # A component's own declaration plus anything it inherits with a reused controller.
  def shared_dirs_for(component)
    registry = ModelrailsUi::Generators::Components
    owners = [component] + registry::EXTRA_STIMULUS.select { |_k, v| v[:source].start_with?("#{component}/") }.keys
    owners.flat_map { |c| (registry::SHARED_JS[c] || []).map { |m| m.fetch(:dir) } }.uniq
  end
end
