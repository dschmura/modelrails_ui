# frozen_string_literal: true

require "test_helper"

# A bordered container has exactly two legal surfaces, and `bg-surface` is not one
# of them (#210).
#
# `bg-surface` is the PAGE. A container painted with it is the same colour as the
# ground it sits on, so it reads as a bare border — and whether that looks
# deliberate depends entirely on what background the host app happens to set. The
# library had drifted into three answers: `card` raised, `list_group` and `table`
# on `bg-surface`, `data_table` with no surface at all, so a list and a table side
# by side read as different kinds of object.
#
# The ruling, stated once in docs/design-tokens.md:
#
#   * `bg-surface-raised` — a card-shaped container that sits ON the page.
#   * `bg-surface-overlay` — a container that floats ABOVE the page (dialog,
#     popover, sheet, menu, tooltip surface).
#
# Derived, not named: any template constant that paints a bordered box is scored,
# so a NEW component picking `bg-surface` fails here rather than quietly adding a
# fourth answer. What this gate cannot see is a bordered box with no surface token
# at all — form controls legitimately set their background elsewhere — so absence
# is not scored, only a wrong choice.
class TestContainerSurface < Minitest::Test
  TEMPLATES = File.expand_path("../lib/generators/modelrails_ui/add/templates", __dir__)
  LEGAL = %w[bg-surface-raised bg-surface-overlay].freeze
  # `bg-surface-sunken` is a well (an inset area INSIDE a container), never the
  # container itself; `bg-surface` is the page.
  ILLEGAL = %w[bg-surface bg-surface-sunken].freeze

  def test_no_bordered_container_is_painted_with_the_page_surface
    offenders = Dir.glob("#{TEMPLATES}/*/*.rb.tt").sort.flat_map do |path|
      component = File.basename(File.dirname(path))

      bordered_class_strings(File.read(path)).filter_map do |str|
        token = str[/\bbg-surface(?:-[a-z]+)?\b/]
        next if token.nil? || LEGAL.include?(token)
        next unless ILLEGAL.include?(token)

        "#{component}: #{token}"
      end
    end

    assert_empty offenders, <<~MSG
      bordered containers painted with a non-container surface:
        #{offenders.join("\n  ")}

      Use bg-surface-raised (sits on the page) or bg-surface-overlay (floats above it).
      See docs/design-tokens.md.
    MSG
  end

  private

  # Class strings that paint a bordered box. Opacity-modified tokens
  # (`bg-surface-sunken/40` on a table header) are row/cell fills inside a
  # container, not the container, so they are deliberately not matched.
  def bordered_class_strings(src)
    src.scan(/"[^"]*"/).select do |str|
      str.include?("border border-border") && str.match?(/\bbg-surface(?:-[a-z]+)?\b/)
    end
  end
end
