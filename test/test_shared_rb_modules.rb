# frozen_string_literal: true

require "test_helper"
require "rails/generators"
require_relative "../lib/generators/modelrails_ui/add/add_generator"

# Shared Ruby modules are the SHARED_JS idea one asset kind over: a plain .rb.tt
# that several component templates depend on, copied once to a fixed destination.
# Without the registry, a non-component .rb.tt inside a component dir would fall
# through to the NON_COMPONENT_RB check and, unregistered, be misfiled into
# app/components/ui/ under its own name — or duplicated per declarer.
class TestSharedRbModules < Minitest::Test
  Components = ModelrailsUi::Generators::Components
  TEMPLATES = File.expand_path("../lib/generators/modelrails_ui/add/templates", __dir__)

  def test_registered_shared_rb_sources_exist_on_disk
    Components::SHARED_RB.each_value do |mods|
      mods.each { |m| assert_path_exists File.join(TEMPLATES, m.fetch(:source)) }
    end
  end

  def test_shared_rb_destinations_are_app_components_ui_paths
    Components::SHARED_RB.each_value do |mods|
      mods.each { |m| assert m.fetch(:dest).start_with?("app/components/ui/") }
    end
  end

  def test_modal_family_declares_the_chrome_module
    %w[dialog sheet drawer].each do |c|
      sources = Components::SHARED_RB.fetch(c).map { |m| m.fetch(:source) }

      assert_includes sources, "dialog/modal_chrome.rb.tt"
    end
  end

  # The misfile invariant, extended: every .rb.tt that is neither a *_component.rb.tt
  # nor claimed by NON_COMPONENT_RB must be claimed as a SHARED_RB source.
  def test_every_unclaimed_rb_tt_is_a_registered_shared_module
    shared_sources = Components::SHARED_RB.values.flatten.map { |m| m.fetch(:source) }.uniq
    on_disk = Dir.glob("#{TEMPLATES}/*/*.rb.tt")
      .reject { |p| File.basename(p).end_with?("_component.rb.tt") }
      .map { |p| p.delete_prefix("#{TEMPLATES}/") }
      .reject { |rel| Components::NON_COMPONENT_RB.key?(rel) }

    assert_equal on_disk.sort, (on_disk & shared_sources).sort,
      "unclaimed non-component .rb.tt would be misfiled: #{(on_disk - shared_sources).inspect}"
  end
end
