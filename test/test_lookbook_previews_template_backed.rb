# frozen_string_literal: true

require "test_helper"

class TestLookbookPreviewsTemplateBacked < Minitest::Test
  PREVIEW_ROOT = File.expand_path(
    "../lib/generators/modelrails_ui/lookbook/templates/previews/ui", __dir__
  )

  # component => scenario methods that must be template-backed (playground excluded)
  PRIMITIVES = {
    "button" => %w[primary secondary danger text_interactive link dont_icon_only_without_label],
    "input" => %w[default required invalid dont_raw_input],
    "textarea" => %w[default invalid dont_raw_textarea],
    "file_input" => %w[default images_only multiple dont_raw_file_input],
    "avatar" => %w[image initials custom_hue dont_interactive_no_label],
    "form_field" => %w[default with_hint with_error required],
    "aspect_ratio" => %w[default square dont_no_content],
    "card" => %w[default with_footer dont_heading_misuse],
    "banner" => %w[default info dismissible dont_dismiss_no_label],
    "list_group" => %w[default links dont_div_rows],
    "chat_bubble" => %w[sent received with_meta dont_color_only_author],
    "footer" => %w[default minimal dont_div_links],
    "iframe" => %w[default responsive dont_no_title],
    "picture" => %w[default formats dont_no_alt],
    "device_mockup" => %w[phone browser dont_decorative_image_no_alt],
    "map_area" => %w[default dont_area_no_alt],
    "timeline" => %w[default variants with_datetime dont_div_steps],
    "scroll_area" => %w[default horizontal dont_no_keyboard_access]
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
        assert_match(/def #{scenario}(; end|\n\s*end)/, src, "#{component}##{scenario} should be empty")
      end
    end
  end

  def test_playground_stays_inline_where_present
    %w[button avatar].each do |component|
      # Renders inline via `ui` — optionally after a setup line (e.g. splitting a
      # two-axis variant/tone cell). Not template-backed.
      assert_match(/def playground\(.*\)\n(?:\s+.+\n)*?\s+ui /, preview_rb(component),
        "#{component} playground should remain an inline explorer")
    end
  end

  DIALOG_SCENARIOS = %w[default large dont_no_title].freeze

  def dialog_template(scenario)
    File.read(File.join(PREVIEW_ROOT, "dialog_component_preview", "#{scenario}.html.erb"))
  end

  def test_dialog_scenarios_are_template_backed
    src = File.read(File.join(PREVIEW_ROOT, "dialog_component_preview.rb"))
    DIALOG_SCENARIOS.each do |scenario|
      assert_path_exists File.join(PREVIEW_ROOT, "dialog_component_preview", "#{scenario}.html.erb")
      assert_match(/def #{scenario}(; end|\n\s*end)/, src, "dialog##{scenario} should be empty")
    end
  end

  def test_dialog_scenarios_teach_shared_modal_and_stay_portable
    DIALOG_SCENARIOS.each do |scenario|
      src = dialog_template(scenario)

      assert_includes src, 'render "shared/modal"', "#{scenario} should teach the shared/modal partial"
      refute_includes src, "f.text_field", "#{scenario} must not use the app form builder"
      refute_includes src, "shared/confirm_dialog", "#{scenario} must not use the app confirm partial"
      refute_includes src, "avatar_for", "#{scenario} must not use the app avatar helper"
    end
  end

  ALERT_DIALOG_SCENARIOS = %w[basic confirm_destructive].freeze
  DRAWER_SCENARIOS = %w[basic with_footer].freeze
  SHEET_SCENARIOS = %w[basic side_left side_bottom].freeze

  OVERLAY_COMPONENTS = {
    "alert_dialog" => {scenarios: ALERT_DIALOG_SCENARIOS, class: "UI::AlertDialogComponent"},
    "drawer" => {scenarios: DRAWER_SCENARIOS, class: "UI::DrawerComponent"},
    "sheet" => {scenarios: SHEET_SCENARIOS, class: "UI::SheetComponent"}
  }.freeze

  def test_overlay_scenarios_are_template_backed
    OVERLAY_COMPONENTS.each do |component, config|
      src = preview_rb(component)
      config[:scenarios].each do |scenario|
        path = File.join(PREVIEW_ROOT, "#{component}_component_preview", "#{scenario}.html.erb")

        assert_path_exists path, "missing overlay template #{path}"
        assert_match(/def #{scenario}(; end|\n\s*end)/, src,
          "#{component}##{scenario} should be an empty template-backed method")
      end
    end
  end

  def test_overlay_scenarios_have_trigger_slot
    OVERLAY_COMPONENTS.each do |component, config|
      config[:scenarios].each do |scenario|
        path = File.join(PREVIEW_ROOT, "#{component}_component_preview", "#{scenario}.html.erb")
        src = File.read(path)

        assert_includes src, "with_trigger",
          "#{component}##{scenario} must include a with_trigger slot so the overlay can be opened"
      end
    end
  end

  def test_overlay_scenarios_use_component_class_directly
    OVERLAY_COMPONENTS.each do |component, config|
      config[:scenarios].each do |scenario|
        path = File.join(PREVIEW_ROOT, "#{component}_component_preview", "#{scenario}.html.erb")
        src = File.read(path)

        assert_includes src, config[:class],
          "#{component}##{scenario} should invoke #{config[:class]} directly"
      end
    end
  end
end
