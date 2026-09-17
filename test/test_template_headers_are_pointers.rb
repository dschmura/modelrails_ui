# frozen_string_literal: true

require "test_helper"
require "modelrails_ui/component_header"

# Every component template's class-level comment is the three-line pointer to
# docs/components/<name>.md; the prose lives in the doc. PENDING shrinks one
# wave at a time and is empty once the migration lands.
class TestTemplateHeadersArePointers < Minitest::Test
  TEMPLATE_ROOT = File.expand_path("../lib/generators/modelrails_ui/add/templates", __dir__)
  DOCS_ROOT = File.expand_path("../docs/components", __dir__)
  H = ModelrailsUi::ComponentHeader

  PENDING = %w[
    accordion accordion_item alert aspect_ratio audio avatar badge banner bottom_nav breadcrumb
    button button_group calendar card card_content card_description card_footer card_header
    card_title carousel chart chat_bubble checkbox collapsible combobox command context_menu copy
    data_table date_picker device_mockup dialog drawer dropdown_menu embed error_summary figure
    file_input floating_label footer form_field gallery hover_card iframe image indicator input
    input_otp kbd label list_group list_group_item map_area mega_menu menubar menubar_menu navbar
    navigation_menu number_input pagination picture popover progress qr_code radio_group range
    rating rating_input resizable scroll_area search_input select separator sheet sidebar skeleton
    speed_dial spinner stepper switch tabs tabs_item textarea timeline timepicker toaster toggle
    toggle_group tooltip video wysiwyg
  ].freeze

  def templates
    Dir[File.join(TEMPLATE_ROOT, "*", "*_component.rb.tt")].sort.map { |f| [File.basename(f, "_component.rb.tt"), f] }
  end

  def test_migrated_templates_carry_only_the_pointer
    offenders = templates.reject { |name, _| PENDING.include?(name) }.reject do |name, file| # rubocop:disable Style/HashExcept
      H.pointer?(H.locate(File.readlines(file)), doc: H.doc_name(name))
    end

    assert_empty offenders.map(&:first), # rubocop:disable Minitest/EmptyLineBeforeAssertionMethods
      "Header is prose, not the three-line pointer — run bin/migrate-component-header: #{offenders.map(&:first).join(", ")}"
  end

  def test_pending_names_are_real_components
    assert_empty PENDING - templates.map(&:first), "PENDING names a template that does not exist"
  end

  def test_every_component_has_a_doc_to_point_at
    templates.each do |name, _|
      assert_path_exists File.join(DOCS_ROOT, "#{H.doc_name(name)}.md"), "#{name}: no doc to point at"
    end
  end
end
