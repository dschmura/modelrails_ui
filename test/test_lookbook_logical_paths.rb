# frozen_string_literal: true

require "test_helper"

# Every Lookbook preview must declare a @logical_path that buckets it into one of the
# 8 canonical catalog sections. Guards against a new/renamed component landing ungrouped
# or in the wrong section. EXPECTED is the single source of truth for the taxonomy.
# Tag form is UNQUOTED: `# @logical_path Forms & Inputs` (lookbook consumes it verbatim).
class TestLookbookLogicalPaths < Minitest::Test
  PREVIEW_ROOT = File.expand_path(
    "../lib/generators/modelrails_ui/lookbook/templates/previews/ui", __dir__
  )

  SECTIONS = [
    "Forms & Inputs", "Actions", "Overlays", "Navigation",
    "Feedback & Status", "Data Display", "Media", "Layout"
  ].freeze

  EXPECTED = {
    "input" => "Forms & Inputs", "textarea" => "Forms & Inputs", "select" => "Forms & Inputs",
    "checkbox" => "Forms & Inputs", "radio_group" => "Forms & Inputs", "switch" => "Forms & Inputs",
    "toggle" => "Forms & Inputs", "toggle_group" => "Forms & Inputs", "range" => "Forms & Inputs",
    "number_input" => "Forms & Inputs", "search_input" => "Forms & Inputs",
    "file_input" => "Forms & Inputs", "input_otp" => "Forms & Inputs", "combobox" => "Forms & Inputs",
    "date_picker" => "Forms & Inputs", "timepicker" => "Forms & Inputs", "calendar" => "Forms & Inputs",
    "rating_input" => "Forms & Inputs", "floating_label" => "Forms & Inputs", "label" => "Forms & Inputs",
    "form_field" => "Forms & Inputs", "wysiwyg" => "Forms & Inputs",
    "button" => "Actions", "button_group" => "Actions", "speed_dial" => "Actions", "command" => "Actions",
    "dialog" => "Overlays", "alert_dialog" => "Overlays", "drawer" => "Overlays", "sheet" => "Overlays",
    "popover" => "Overlays", "tooltip" => "Overlays", "hover_card" => "Overlays",
    "dropdown_menu" => "Overlays", "context_menu" => "Overlays", "menubar" => "Overlays",
    "navbar" => "Navigation", "sidebar" => "Navigation", "breadcrumb" => "Navigation",
    "tabs" => "Navigation", "bottom_nav" => "Navigation", "mega_menu" => "Navigation",
    "navigation_menu" => "Navigation", "footer" => "Navigation",
    "alert" => "Feedback & Status", "banner" => "Feedback & Status", "badge" => "Feedback & Status",
    "progress" => "Feedback & Status", "spinner" => "Feedback & Status", "skeleton" => "Feedback & Status",
    "indicator" => "Feedback & Status", "stepper" => "Feedback & Status", "toaster" => "Feedback & Status",
    "card" => "Data Display", "list_group" => "Data Display", "data_table" => "Data Display",
    "timeline" => "Data Display", "accordion" => "Data Display", "collapsible" => "Data Display",
    "chat_bubble" => "Data Display", "avatar" => "Data Display", "kbd" => "Data Display",
    "rating" => "Data Display", "chart" => "Data Display",
    "image" => "Media", "picture" => "Media", "figure" => "Media", "gallery" => "Media",
    "audio" => "Media", "video" => "Media", "embed" => "Media", "iframe" => "Media",
    "carousel" => "Media", "qr_code" => "Media", "device_mockup" => "Media",
    "map_area" => "Media", "aspect_ratio" => "Media",
    "separator" => "Layout", "scroll_area" => "Layout", "resizable" => "Layout"
  }.freeze

  def all_preview_components
    Dir.glob(File.join(PREVIEW_ROOT, "*_component_preview.rb"))
      .map { |p| File.basename(p, "_component_preview.rb") }
  end

  def declared_logical_path(component)
    src = File.read(File.join(PREVIEW_ROOT, "#{component}_component_preview.rb"))
    src[/^\s*#\s*@logical_path\s+(.+?)\s*$/, 1]
  end

  def test_every_preview_is_in_the_expected_map
    extra = all_preview_components - EXPECTED.keys
    missing = EXPECTED.keys - all_preview_components

    assert_empty extra, "previews with no EXPECTED section (add them to the map): #{extra.sort}"
    assert_empty missing, "EXPECTED components with no preview file: #{missing.sort}"
  end

  def test_every_preview_declares_its_expected_logical_path
    all_preview_components.each do |component|
      actual = declared_logical_path(component)

      refute_nil actual, "#{component}: missing `@logical_path` tag"
      assert_includes SECTIONS, actual, "#{component}: `#{actual}` is not a canonical section"
      assert_equal EXPECTED[component], actual, "#{component}: expected `#{EXPECTED[component]}`, got `#{actual}`"
    end
  end
end
