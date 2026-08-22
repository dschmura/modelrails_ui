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

  # wrapper_attrs sits OUTSIDE the CHROME list above on purpose: sheet (transform
  # values) and drawer (same) must override it. That leaves the override itself
  # unguarded against the exact failure mode that motivated this refactor — a
  # hand-rolled re-implementation drifting from ModalChrome instead of extending
  # it. A delegating override (`base = super; base[...] = ...; base`) is fine; a
  # from-scratch body is not — it can silently drop @extra_class handling, the
  # open-value data attr, or html_attrs merging the way sheet's old double
  # @extra_class bug did.
  def test_family_wrapper_attrs_overrides_delegate_to_super
    offenders = FAMILY.filter_map do |rel|
      src = File.read(File.join(TEMPLATES, rel))
      match = src.match(/^([ \t]*)def wrapper_attrs\b.*?\n(.*?)^\1end\b/m)
      next unless match

      "#{rel}: wrapper_attrs does not call super" unless match[2].include?("super")
    end

    assert_empty offenders, "wrapper_attrs overrides must delegate to ModalChrome via super:\n  #{offenders.join("\n  ")}"
  end
end
