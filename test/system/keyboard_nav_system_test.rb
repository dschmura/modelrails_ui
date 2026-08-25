# frozen_string_literal: true

require "system_test_helper"

# The shared module extracted from the menu family, exercised directly.
#
# Worth its own file because the component-level nets do not reach all of it: the
# ArrowUp no-active-option branch is unreachable through both of its callers —
# combobox's filter() re-seeds the active option to visible[0] on every open and
# input, and command does the same — so a mutation removing that guard passes every
# component test. It is still correct APG behavior and still the exact branch that
# shipped broken once, so it is pinned here rather than left to a future caller to
# rediscover.
#
# This is the payoff of extraction: movement logic that was four inlined switches is
# now a pure function that can be asserted without driving a component.
BrowserHarness.scenario("keyboard_nav/module", modules: %w[keyboard/keyboard_nav]) do
  <<~HTML.html_safe
    <script type="module">
      import { nextActive, TypeAhead } from "keyboard/keyboard_nav"
      window.__kbd = { nextActive, TypeAhead }
    </script>
    <ul id="items">
      <li>Alpha</li><li>Beta</li><li>Gamma</li>
    </ul>
  HTML
end

class KeyboardNavSystemTest < BrowserTestCase
  def setup
    super
    visit_scenario("keyboard_nav/module")
    Timeout.timeout(5) { sleep 0.02 until page.evaluate_script("!!window.__kbd") }
  end

  # Returns the text of nextActive(items, current, key) over the three <li>s.
  def move(current, key)
    page.evaluate_script(<<~JS)
      (() => {
        const items = Array.from(document.querySelectorAll("#items li"))
        const el = window.__kbd.nextActive(items, #{current}, "#{key}")
        return el ? el.textContent : null
      })()
    JS
  end

  # --- nextActive ----------------------------------------------------------

  def test_arrow_down_advances
    assert_equal "Gamma", move(1, "ArrowDown")
  end

  def test_arrow_down_wraps
    assert_equal "Alpha", move(2, "ArrowDown")
  end

  def test_arrow_up_retreats
    assert_equal "Alpha", move(1, "ArrowUp")
  end

  def test_arrow_up_wraps
    assert_equal "Gamma", move(0, "ArrowUp")
  end

  # The branch no component test can reach. APG: with nothing active, ArrowUp enters
  # at the END. The modulo alone lands one short — the #661 class of bug.
  def test_arrow_up_with_nothing_active_enters_at_the_last_item
    assert_equal "Gamma", move(-1, "ArrowUp")
  end

  # Its ArrowDown counterpart needs no guard: (-1 + 1) % n is already 0.
  def test_arrow_down_with_nothing_active_enters_at_the_first_item
    assert_equal "Alpha", move(-1, "ArrowDown")
  end

  def test_home_and_end_are_absolute
    assert_equal "Alpha", move(2, "Home")
    assert_equal "Gamma", move(0, "End")
  end

  def test_a_key_that_does_not_move_returns_nothing
    assert_nil move(1, "Enter")
  end

  def test_an_empty_set_returns_nothing
    result = page.evaluate_script('window.__kbd.nextActive([], -1, "ArrowDown")')

    assert_nil result
  end

  # --- TypeAhead -----------------------------------------------------------

  def match_for(keys, from)
    page.evaluate_script(<<~JS)
      (() => {
        const items = Array.from(document.querySelectorAll("#items li"))
        const ta = new window.__kbd.TypeAhead()
        #{keys.chars.map { |c| "ta.push(#{c.inspect});" }.join(" ")}
        return ta.match(items, #{from})
      })()
    JS
  end

  def test_match_finds_the_next_item_by_prefix
    assert_equal 2, match_for("g", 0)
  end

  def test_match_wraps_to_find_an_earlier_item
    assert_equal 0, match_for("a", 2)
  end

  def test_match_accumulates_the_buffer_across_keystrokes
    assert_equal 1, match_for("be", 0)
  end

  def test_match_returns_minus_one_when_nothing_matches
    assert_equal(-1, match_for("z", 0))
  end

  # The skip predicate is menubar's shape: it cannot pre-filter, because its indices
  # are co-indexed with menuOutlets, so the returned index must be into the ORIGINAL
  # array with skipped entries passed over.
  def test_skip_passes_over_an_item_without_shifting_the_returned_index
    result = page.evaluate_script(<<~JS)
      (() => {
        const items = Array.from(document.querySelectorAll("#items li"))
        items[1].setAttribute("aria-disabled", "true")
        const ta = new window.__kbd.TypeAhead()
        ta.push("b")
        return ta.match(items, 0, { skip: (el) => el.getAttribute("aria-disabled") === "true" })
      })()
    JS

    assert_equal(-1, result)
  end

  def test_cancel_clears_the_buffer
    result = page.evaluate_script(<<~JS)
      (() => {
        const items = Array.from(document.querySelectorAll("#items li"))
        const ta = new window.__kbd.TypeAhead()
        ta.push("g")
        ta.cancel()
        ta.push("a")
        return ta.match(items, 0)
      })()
    JS

    assert_equal 0, result
  end
end
