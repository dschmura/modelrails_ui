# frozen_string_literal: true

require "test_helper"

# WCAG 2.3.3 Animation from Interactions (AAA): motion a person sets off by using
# the page can be turned off. The operating-system "reduce motion" setting is how
# they turn it off, so every utility that can MOVE something is written behind
# `motion-safe:` and does nothing under `prefers-reduced-motion: reduce`.
#
# "Move" is the criterion's word, and it is narrower than "animate". A colour or
# opacity fade is not motion, so `transition-colors`, `transition-opacity` and
# `transition-shadow` stay bare. The utilities guarded here are the ones whose
# property list includes transform, translate, scale or rotate: bare `transition`,
# `transition-all`, `transition-transform`, and every `animate-*` keyframe. An
# arbitrary `transition-[…]` list counts too when it names anything beyond a repaint
# (a `width` slides content across the screen just as a translate does).
#
# One convention rather than two: the `x motion-reduce:x-none` pairing works too,
# but it can only be checked by knowing which class string the counterpart sits in,
# and a string split across lines defeats that. `motion-safe:` is checkable token by
# token, and it is the form the shipped stylesheet already documents.
#
# Nothing else can catch this: axe has no 2.3.3 rule, and the render tests assert
# the classes a component renders, not whether they move.
class TestMotionRespectsReducedMotion < Minitest::Test
  TEMPLATES = File.expand_path("../lib/generators/modelrails_ui/add/templates", __dir__)
  MOTION = /(?<=["'`\s])(transition|transition-all|transition-transform|animate-[a-z0-9-]+)(?=["'`\s]|\z)/
  ARBITRARY_TRANSITION = /(?<=["'`\s])transition-\[([^\]]+)\](?=["'`\s]|\z)/
  # A transition-[…] list moves something unless every property in it only repaints.
  REPAINT_PROPERTIES = %w[color background-color border-color outline-color text-decoration-color fill stroke opacity box-shadow].freeze
  COMMENT_LINE = %r{\A\s*(#|//|\*|/\*|<%#)}

  # The criterion exempts motion that is essential to what is conveyed. Each entry
  # is a decision with its reason, not a way to quiet the test.
  ESSENTIAL = {
    "spinner/spinner_component.rb.tt animate-spin" =>
      "the spin IS the busy signal; a still spinner conveys nothing (docs/components/spinner.md)"
  }.freeze

  def motion_tokens(line)
    arbitrary = line.scan(ARBITRARY_TRANSITION).flatten.reject { |list| (list.split(",") - REPAINT_PROPERTIES).empty? }
    line.scan(MOTION).flatten + arbitrary.map { |list| "transition-[#{list}]" }
  end

  def template_files
    Dir.glob(File.join(TEMPLATES, "**/*.{tt,js,erb}"))
  end

  # Every bare motion utility as [file-and-token, file:line-and-token].
  def bare_motion(path)
    relative = path.delete_prefix("#{TEMPLATES}/")
    File.readlines(path).each_with_index.flat_map do |line, index|
      next [] if line.match?(COMMENT_LINE)

      motion_tokens(line).map { |token| ["#{relative} #{token}", "#{relative}:#{index + 1} #{token}"] }
    end
  end

  def all_bare_motion = template_files.flat_map { |path| bare_motion(path) }

  # POSITIVE CONTROL: the scan must still see the templates and must still match a
  # bare motion token, or an empty result below means nothing.
  def test_the_scan_reads_the_templates_and_recognises_bare_motion
    assert_operator template_files.size, :>, 50, "expected the add-generator templates under #{TEMPLATES}"
    assert_equal %w[transition-all animate-spin transition transition-[width]],
      motion_tokens(%(class: "p-2 transition-all animate-spin motion-safe:transition-transform transition ) +
                    %(transition-[width] transition-[color,box-shadow] motion-safe:transition-[height]"))
  end

  def test_no_template_moves_anything_outside_motion_safe
    offenders = all_bare_motion.reject { |key, _| ESSENTIAL.key?(key) }.map(&:last)

    assert_empty offenders, <<~MSG
      These utilities animate transform, so they move something on screen, and they are
      not behind `motion-safe:`. Someone who has asked their OS to reduce motion gets it
      anyway (WCAG 2.3.3). Write them `motion-safe:<utility>`. If what changes is only
      colour or opacity, the narrower `transition-colors` / `transition-opacity` is the
      honest class and needs no prefix:

        #{offenders.join("\n  ")}
    MSG
  end

  # An exemption that no longer matches anything would silently widen the next time
  # something with that name appears, so a stale one fails.
  def test_every_essential_exemption_still_matches_a_template
    found = all_bare_motion.map(&:first)

    assert_empty ESSENTIAL.keys - found, "remove ESSENTIAL entries that no longer match a bare motion utility"
  end
end
