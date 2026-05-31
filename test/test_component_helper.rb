# frozen_string_literal: true

require "test_helper"

class TestComponentHelper < Minitest::Test
  include ModelrailsUi::ComponentHelper

  def render(component, &) = component

  def test_raises_with_class_name_when_component_not_found
    error = assert_raises(ModelrailsUi::ComponentNotFoundError) do
      ui("nonexistent")
    end
    assert_match "UI::NonexistentComponent", error.message
  end

  def test_raises_with_generator_hint_when_component_not_found
    error = assert_raises(ModelrailsUi::ComponentNotFoundError) do
      ui("nonexistent")
    end
    assert_match "rails g modelrails_ui:add nonexistent", error.message
  end

  def test_multi_word_name_in_generator_hint
    error = assert_raises(ModelrailsUi::ComponentNotFoundError) do
      ui("ghost_widget")
    end
    assert_match "rails g modelrails_ui:add ghost_widget", error.message
    assert_match "UI::GhostWidgetComponent", error.message
  end

  def test_component_not_found_error_is_a_modelrails_ui_error
    assert_operator ModelrailsUi::ComponentNotFoundError, :<, ModelrailsUi::Error
  end

  def test_ui_accepts_symbol
    error = assert_raises(ModelrailsUi::ComponentNotFoundError) do
      ui(:missing_thing)
    end

    assert_match "UI::MissingThingComponent", error.message
  end

  def test_ui_symbol_and_string_resolve_same_error
    symbol_error = assert_raises(ModelrailsUi::ComponentNotFoundError) { ui(:ghost) }
    string_error = assert_raises(ModelrailsUi::ComponentNotFoundError) { ui("ghost") }

    assert_equal symbol_error.message, string_error.message
  end
end
