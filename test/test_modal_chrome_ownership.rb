# frozen_string_literal: true

require "test_helper"

# The chrome had four hand-copied implementations and they drifted (sheet applied
# @extra_class twice — caught 2026-08-22). ModalChrome is now the single owner:
# no modal-family component template may re-define a chrome method.
class TestModalChromeOwnership < Minitest::Test
  TEMPLATES = File.expand_path("../lib/generators/modelrails_ui/add/templates", __dir__)
  FAMILY = %w[dialog/dialog_component.rb.tt sheet/sheet_component.rb.tt drawer/drawer_component.rb.tt].freeze
  CHROME = %w[call trigger_area dialog_tag header close_button body description_tag
    footer_area close_label close_icon setup_modal_chrome].freeze

  def test_family_templates_do_not_redefine_chrome_methods
    offenders = FAMILY.flat_map do |rel|
      src = File.read(File.join(TEMPLATES, rel))
      CHROME.filter_map { |m| "#{rel}: def #{m}" if src.match?(/^\s*def #{m}\b/) }
    end

    assert_empty offenders, "chrome has ONE owner (ModalChrome):\n  #{offenders.join("\n  ")}"
  end

  def test_chrome_module_defines_every_chrome_method
    src = File.read(File.join(TEMPLATES, "dialog/modal_chrome.rb.tt"))
    missing = CHROME.reject { |m| src.match?(/^\s*def #{m}\b/) }

    assert_empty missing, "ModalChrome is missing: #{missing.inspect}"
  end
end
