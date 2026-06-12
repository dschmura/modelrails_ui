# frozen_string_literal: true

require "test_helper"
require "rails/generators"
require_relative "../lib/generators/modelrails_ui/add/add_generator"

class TestAddGeneratorPartialRouting < Minitest::Test
  # allocate skips #initialize (which requires the components argument); the
  # routing helper is pure and touches no instance state.
  def destination_for(file)
    ModelrailsUi::Generators::AddGenerator.allocate.send(:html_erb_destination, file)
  end

  def test_leading_underscore_partial_routes_to_app_views_shared
    assert_equal "app/views/shared/_modal.html.erb", destination_for("_modal.html.erb")
  end

  def test_component_sidecar_template_routes_to_app_components_ui
    assert_equal "app/components/ui/tabs_component.html.erb", destination_for("tabs_component.html.erb")
  end
end
