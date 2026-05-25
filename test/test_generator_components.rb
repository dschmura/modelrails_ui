# frozen_string_literal: true

require "test_helper"

class TestGeneratorComponents < Minitest::Test
  EXPECTED_COMPONENTS = %w[
    button alert accordion
    badge avatar card separator label skeleton progress aspect_ratio
  ].freeze

  def test_all_components_are_supported
    generator_path = File.expand_path("../lib/generators/view_primitives/add/add_generator.rb", __dir__)
    source = File.read(generator_path)

    EXPECTED_COMPONENTS.each do |component|
      assert_match(/\b#{Regexp.escape(component)}\b/, source,
        "Expected #{component} to be in SUPPORTED_COMPONENTS")
    end
  end
end
