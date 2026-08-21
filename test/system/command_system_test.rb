# frozen_string_literal: true

require "system_test_helper"
load_component "command", "command_component.rb.tt"

# Also an end-to-end check of the `search` shared-module namespace: the controller imports
# `search/command_score` by bare specifier, so if SHARED_JS did not register it the import
# would fail here exactly as it would in a fork.
BrowserHarness.scenario("command/fuzzy", controllers: %w[command], modules: %w[search/command_score]) do
  view = ActionController::Base.new.view_context
  item = ->(value, keywords = nil) do
    attrs = {type: "button", class: UI::CommandComponent::ITEM, data: {command_value: value}}
    attrs[:data][:command_keywords] = keywords if keywords
    view.tag.button(value, **attrs)
  end
  UI::CommandComponent.new.render_in(view) do |c|
    c.with_trigger { "Open" }
    view.tag.div(
      view.safe_join([item.call("Groups"), item.call("Group Policy"),
        item.call("Settings", "preferences configuration"), item.call("New document")]),
      class: UI::CommandComponent::GROUP_WRAPPER, data: {command_group: true}
    )
  end
end

# Ranking only exists at runtime — the render lane sees the authored order and nothing else.
class CommandSystemTest < BrowserTestCase
  def setup
    super
    visit_scenario("command/fuzzy")
    # The trigger slot renders inside a span carrying the open action, not a button.
    find("[data-action='click->command#open']").click
    find("[data-command-target=input]")
  end

  def search(query) = find("[data-command-target=input]").set(query)
  def visible_items = page.all("[data-command-value]:not([hidden])").map(&:text)

  def test_matches_a_subsequence_that_is_not_a_substring
    search("nd")

    assert_equal ["New document"], visible_items
  end

  # The control: proves the case above genuinely needs fuzzy matching.
  def test_the_query_is_not_a_substring_of_the_item
    refute_includes "new document", "nd"
  end

  def test_ranks_the_better_match_first
    search("gp")

    assert_equal "Group Policy", visible_items.first
  end

  def test_finds_an_item_by_a_keyword_it_does_not_display
    search("configuration")

    assert_equal ["Settings"], visible_items
  end

  def test_the_scorer_module_actually_loaded
    search("nd")

    assert_no_stimulus_errors
  end
end
