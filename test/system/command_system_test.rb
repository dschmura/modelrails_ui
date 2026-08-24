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

# Mirrors the documented separator example (docs/components/command.md): a plain
# <hr> between groups, inside the role="listbox". An <hr>'s implicit
# role="separator" is an illegal listbox child (axe aria-required-children,
# critical), so the controller must neutralize caller-supplied rules.
BrowserHarness.scenario("command/separator", controllers: %w[command], modules: %w[search/command_score]) do
  view = ActionController::Base.new.view_context
  item = ->(value) do
    view.tag.button(value, type: "button", class: UI::CommandComponent::ITEM,
      data: {command_value: value})
  end
  group = ->(*items) do
    view.tag.div(view.safe_join(items), class: UI::CommandComponent::GROUP_WRAPPER,
      data: {command_group: true})
  end
  UI::CommandComponent.new.render_in(view) do |c|
    c.with_trigger { "Open" }
    view.safe_join([
      group.call(item.call("Groups")),
      view.tag.hr(class: UI::CommandComponent::SEPARATOR),
      group.call(item.call("New document"))
    ])
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

  # Invariant pin for navigate's entry-parity branch: the palette's input lives
  # INSIDE the panel, so once Escape closes it no keyboard path reaches
  # navigate — ArrowUp must NOT reopen. If a refactor ever routes keys to the
  # controller while closed (the combobox reopen shape), this turns that
  # parity branch live and this example catches the contract change.
  def test_stays_closed_on_arrow_up_after_escape
    press(:Escape)

    assert_no_selector "[data-command-target=input]"

    press(:Up)

    assert_no_selector "[data-command-target=input]"
  end

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

  # A caller-supplied <hr> — the shape the component's own SEPARATOR constant and
  # docs example instruct — must not reach the a11y tree as a listbox child.
  def test_a_caller_supplied_separator_is_not_an_illegal_listbox_child
    visit_scenario("command/separator")
    find("[data-action='click->command#open']").click
    find("[data-command-target=input]")

    rule = find("hr", visible: :all)

    assert_equal "presentation", rule[:role]
    assert_equal "true", rule["aria-hidden"]
  end
end
