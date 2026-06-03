# frozen_string_literal: true

require "test_helper"

class TestSharedModalTemplate < Minitest::Test
  PATH = File.expand_path(
    "../lib/generators/modelrails_ui/add/templates/dialog/_modal.html.erb", __dir__
  )

  def source
    @source ||= File.read(PATH)
  end

  def test_partial_exists
    assert_path_exists PATH, "dialog add-template should ship _modal.html.erb"
  end

  def test_declares_trigger_local_with_default
    assert_includes source, "trigger: nil"
    assert_includes source, 'trigger_class: "btn-secondary"'
  end

  def test_has_complete_and_surface_branches
    assert_includes source, "if trigger.present?"
    assert_includes source, "wrapper: true"
    assert_includes source, "wrapper: false"
    assert_includes source, 'body_id: "modal-body"'
    assert_includes source, "d.with_trigger"
  end
end
