# frozen_string_literal: true

require "test_helper"

# An anchored panel wider than the screen overflows it, and no
# `position-try-fallbacks` value can rescue that: flipping needs room on the
# other side, and a panel wider than the viewport has none (#211).
#
# So every anchored panel whose width the COMPONENT decides carries a cap
# resolved against the viewport. The one exemption is a panel sized by its own
# trigger (`width: anchor-size(width)`): its width is the anchor's, which is
# already on screen, and capping it would make the panel narrower than the
# trigger it exists to line up with.
#
# Derived from the placement machinery rather than a named list, so a NEW
# anchored component fails here instead of quietly shipping an unbounded panel.
# What this gate cannot see is a file holding BOTH an anchor-sized panel and a
# component-sized one — the exemption is per file, not per constant. No template
# does that today; if one ever does, tighten this to scan constants.
class TestAnchoredPanelViewportCap < Minitest::Test
  TEMPLATES = File.expand_path("../lib/generators/modelrails_ui/add/templates", __dir__)
  # Every anchored panel in the library declares a fallback beside its
  # position-area cell, which makes it the marker for "this floats against the
  # viewport" rather than flowing in the document.
  ANCHORED = "position-try-fallbacks"
  # Sized by the anchor, and therefore already bounded by it.
  ANCHOR_SIZED = "anchor-size(width)"
  # Any ceiling resolved against the viewport counts, so a panel with its own
  # ceiling can combine the two with min() rather than emitting a second
  # max-width utility — two max-widths on one element is a cascade race, not a
  # smaller-wins.
  VIEWPORT_CAP = /max-w-\[[^\]]*100vw[^\]]*\]/

  def test_every_anchored_panel_the_component_sizes_is_viewport_bounded
    anchored = Dir.glob("#{TEMPLATES}/*/*.rb.tt").sort.select do |path|
      File.read(path).include?(ANCHORED)
    end

    refute_empty anchored,
      "derivation matched no templates — the placement marker must have changed"

    offenders = anchored.filter_map do |path|
      src = File.read(path)
      next if src.include?(ANCHOR_SIZED)
      next if src.match?(VIEWPORT_CAP)

      File.basename(File.dirname(path))
    end

    assert_empty offenders, <<~MSG
      anchored panels with no viewport-bounded max-width:
        #{offenders.join("\n  ")}

      Add max-w-[calc(100vw-2rem)] — or max-w-[min(<own ceiling>,calc(100vw-2rem))]
      when the panel already has a ceiling of its own. Never a second max-w-*
      utility: two max-widths on one element is a cascade race.
      See docs/anchored-panels.md.
    MSG
  end
end
