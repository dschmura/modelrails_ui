# frozen_string_literal: true

require "test_helper"
require "generators/modelrails_ui/components"

# STRUCTURE-only checks for the form_draft partial. The app 0b system specs
# prove behavior (save/recover/announce) in a real browser.
class FormDraftRenderTest < Minitest::Test
  TEMPLATE_DIR = File.expand_path(
    "../../lib/generators/modelrails_ui/add/templates/form_draft", __dir__
  )

  def partial_source
    @partial_source ||= File.read(File.join(TEMPLATE_DIR, "_form_draft_notice.html.erb"))
  end

  def test_component_is_registered
    assert_includes ModelrailsUi::Generators::Components.supported, "form_draft"
  end

  def test_template_dir_ships_partial_and_controller
    files = Dir.children(TEMPLATE_DIR).sort
    assert_equal ["_form_draft_notice.html.erb", "form_draft_controller.js"], files
  end

  def test_notice_chip_contract
    assert_includes partial_source, 'data-form-draft-target="notice"'
    assert_includes partial_source, "bg-warning-surface"
    assert_includes partial_source, "text-warning"
    assert_includes partial_source, "border-warning-border"
    refute_includes partial_source, "text-warning/", "no opacity modifier on signal text (AAA)"
  end

  def test_buttons_are_real_non_submitting_buttons
    assert_equal 2, partial_source.scan('type="button"').size
    assert_includes partial_source, 'data-action="form-draft#recover"'
    assert_includes partial_source, 'data-action="form-draft#discard"'
    refute_includes partial_source, "link_to", "no link_to-as-button (episode anti-pattern)"
  end

  def test_buttons_are_full_design_system_buttons_at_44x44
    # Spec constraint: both buttons must be full .btn-* family buttons (which
    # carry min-height/min-width via --form-input-height) with focus-ring —
    # never the color-only, unsized :text variant (.btn-text/.btn-text-*).
    assert_equal 2, partial_source.scan("btn-secondary").size
    assert_equal 2, partial_source.scan("focus-ring").size
    refute_match(/btn-text/, partial_source, "no :text-variant inline links (never 44x44-exempt)")
  end

  def test_status_region_is_stable_and_separate_from_the_chip
    assert_includes partial_source, 'data-form-draft-target="status"'
    assert_includes partial_source, 'role="status"'
    assert_includes partial_source, 'aria-live="polite"'
    assert_includes partial_source, 'aria-atomic="true"'
    assert_includes partial_source, "sr-only"
  end

  def test_all_copy_is_i18n_with_defaults
    %w[form_draft.notice form_draft.recover form_draft.discard
       form_draft.found form_draft.restored form_draft.discarded].each do |key|
      assert_includes partial_source, key
    end
  end
end
