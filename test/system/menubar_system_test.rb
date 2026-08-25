# frozen_string_literal: true

require "system_test_helper"
require "securerandom"
load_component "menubar", "menubar_menu_component.rb.tt"
load_component "menubar", "menubar_component.rb.tt"

# The behaviour half of menubar. Until now the gem proved menubar structure in the render
# lane and left every keyboard guarantee to a consuming app's browser spec — which runs
# against a VENDORED copy and so cannot fail on a template change. These examples pin the
# bar-level contract here, where a template edit can break it.
#
# Written as characterization coverage ahead of the shared keyboard primitive: type-ahead
# is duplicated between `menu` and `menubar`, and extracting it needs a net on both sides.
BrowserHarness.scenario("menubar/bar", controllers: %w[menubar menu], modules: %w[overlays/top_layer]) do
  view = ActionController::Base.new.view_context
  UI::MenubarComponent.new(label: "Main").render_in(view) do |bar|
    bar.with_menu(label: "File") do |m|
      m.with_item { "New" }
      m.with_item { "Open" }
    end
    bar.with_menu(label: "Edit") do |m|
      m.with_item { "Undo" }
      m.with_item(disabled: true) { "Redo" }
      m.with_item { "Rename" }
    end
    bar.with_menu(label: "View") do |m|
      m.with_item { "Zoom in" }
    end
    nil
  end
end

class MenubarSystemTest < BrowserTestCase
  def setup
    super
    visit_scenario("menubar/bar")
    find("[data-menubar-target=item]", match: :first)
  end

  def bar_items = page.all("[data-menubar-target=item]")
  def focused_text = page.evaluate_script("document.activeElement.textContent.trim()")

  # Focus a bar item WITHOUT opening its menu. Clicking would not do: the trigger carries
  # `click->menu#toggle`, so a click opens the submenu and moves focus onto its first item —
  # which is the bar's documented click behaviour, just not the state these examples pin.
  def focus_bar_item(label)
    bar_items.find { |b| b.text == label }.execute_script("this.focus()")
  end

  def open_menu(label)
    focus_bar_item(label)
    press(:Down)
    find("[data-menu-target=menu]")
  end

  # --- pair-1 contract: type-ahead ----------------------------------------
  # The half of the pair that lives in menubar_controller. Its accessor shape differs
  # from menu's (itemTargets + inline aria-disabled filter + focusItem(index) vs
  # enabledItems + focusItem(element)) — that difference is the whole design question
  # for the extraction, so it is pinned rather than described.

  def test_type_ahead_at_the_bar_level_jumps_to_a_matching_item
    focus_bar_item("File")

    press("v")

    assert_equal "View", focused_text
  end

  def test_type_ahead_wraps_past_the_end_of_the_bar
    focus_bar_item("View")

    press("f")

    assert_equal "File", focused_text
  end

  def test_type_ahead_accumulates_a_multi_character_buffer
    focus_bar_item("File")

    press("e")

    assert_equal "Edit", focused_text
  end

  # A non-matching key must not move focus — the scan runs the full ring and gives up
  # rather than landing on the neighbour.
  def test_type_ahead_with_no_match_leaves_focus_alone
    focus_bar_item("File")

    press("z")

    assert_equal "File", focused_text
  end

  # --- the MENU side of the pair, reached through the bar ------------------
  # Type-ahead inside an open submenu is menu_controller's, not menubar's: this pins
  # the enabledItems pre-filter. Mutation-checked — stubbing enabledItems to return
  # itemTargets unfiltered fails exactly this example and nothing else.
  #
  # Its menubar counterpart is NOT pinned here, and cannot be: menubar filters
  # aria-disabled inline inside typeAhead, but `with_menu` exposes no `disabled:`
  # option, so no bar item can be disabled through the public API. That branch is
  # reachable only by a consumer hand-writing aria-disabled onto a bar item. Worth
  # settling during the shared-primitive extraction — one side of the pair carries a
  # filter the component API cannot exercise.

  def test_type_ahead_inside_a_menu_skips_a_disabled_item
    open_menu("Edit")

    press("r")

    assert_equal "Rename", focused_text
  end

  # --- bar-level invariants the extraction must not disturb ----------------
  # menubar's ←/→ are explicitly OUT of scope for the shared primitive (the co-indexed
  # itemTargets/menuOutlets contract cannot be engine config). Pinned so an over-eager
  # extraction that swallows them fails here.

  def test_arrow_right_moves_between_bar_items
    focus_bar_item("File")

    press(:Right)

    assert_equal "Edit", focused_text
  end

  def test_arrow_right_wraps_at_the_end_of_the_bar
    focus_bar_item("View")

    press(:Right)

    assert_equal "File", focused_text
  end

  def test_no_stimulus_errors_driving_the_bar
    focus_bar_item("File")
    press("v")
    press(:Right)

    assert_no_stimulus_errors
  end
end
