# frozen_string_literal: true

require "test_helper"

class TestLookbookPreviewsTemplateBacked < Minitest::Test
  PREVIEW_ROOT = File.expand_path(
    "../lib/generators/modelrails_ui/lookbook/templates/previews/ui", __dir__
  )

  # component => scenario methods that must be template-backed (playground excluded)
  PRIMITIVES = {
    "button"     => %w[primary secondary danger text_interactive link dont_icon_only_without_label],
    "input"      => %w[default required invalid dont_raw_input],
    "textarea"   => %w[default invalid dont_raw_textarea],
    "file_input" => %w[default images_only multiple dont_raw_file_input],
    "avatar"     => %w[image initials custom_hue dont_interactive_no_label]
  }.freeze

  def preview_rb(component)
    File.read(File.join(PREVIEW_ROOT, "#{component}_component_preview.rb"))
  end

  def test_each_primitive_scenario_has_a_sibling_template
    PRIMITIVES.each do |component, scenarios|
      scenarios.each do |scenario|
        path = File.join(PREVIEW_ROOT, "#{component}_component_preview", "#{scenario}.html.erb")
        assert_path_exists path, "missing sibling template #{path}"
      end
    end
  end

  def test_primitive_scenario_methods_are_empty
    PRIMITIVES.each do |component, scenarios|
      src = preview_rb(component)
      scenarios.each do |scenario|
        assert_match(/def #{scenario}; end/, src, "#{component}##{scenario} should be empty")
      end
    end
  end

  def test_playground_stays_inline_where_present
    %w[button avatar].each do |component|
      assert_match(/def playground\(.*\)\n\s+ui /, preview_rb(component),
        "#{component} playground should remain an inline explorer")
    end
  end
end
