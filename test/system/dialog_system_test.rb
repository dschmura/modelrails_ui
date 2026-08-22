# frozen_string_literal: true

require "system_test_helper"
require "securerandom"
load_component "dialog", "modal_chrome.rb.tt"
load_component "dialog", "dialog_component.rb.tt"

# Two dialogs, the second opened from inside the first — the ordinary reason to stack.
BrowserHarness.scenario("dialog/stacked", controllers: %w[modal]) do
  view = ActionController::Base.new.view_context
  inner = UI::DialogComponent.new(title: "Discard changes?", id: "inner-dialog").render_in(view) do |c|
    c.with_trigger { "Discard" }
    view.tag.p("The confirm sits above the form it was opened from.")
  end
  UI::DialogComponent.new(title: "Edit project", id: "outer-dialog").render_in(view) do |c|
    c.with_trigger { "Open form" }
    inner
  end
end

# `modal_controller` warned "Stacked modals are not supported" and then called showModal()
# anyway. The browser has always supported it; these hold the behaviour the warning was
# wrong about. None of it is visible to the render lane.
class DialogSystemTest < BrowserTestCase
  def setup
    super
    visit_scenario("dialog/stacked")
    # Trigger slots render inside a span carrying the open action, not a button. The
    # inner trigger is scoped to the dialog so it is not confused with the outer one.
    find("[data-action='click->modal#open']", match: :first).click
    find("dialog[open]") # blocks until it opens; not an assertion in a lifecycle hook
    within("dialog[open]") { find("[data-action='click->modal#open']").click }
  end

  def open_dialogs = page.all("dialog[open]", visible: :all).length

  def test_the_second_dialog_opens_above_the_first
    assert_equal 2, open_dialogs
  end

  def test_focus_moves_into_the_topmost_dialog
    inner = page.evaluate_script(<<~JS)
      (() => {
        const dialogs = [...document.querySelectorAll("dialog[open]")];
        const top = dialogs[dialogs.length - 1];
        return top.contains(document.activeElement);
      })()
    JS

    assert inner
  end

  def test_escape_closes_only_the_topmost
    press(:Escape)

    assert_selector "dialog[open]", count: 1, visible: :all
  end

  def test_a_second_escape_closes_the_one_beneath
    press(:Escape)

    assert_selector "dialog[open]", count: 1, visible: :all

    press(:Escape)

    assert_no_selector "dialog[open]", visible: :all
    assert_no_stimulus_errors
  end
end
