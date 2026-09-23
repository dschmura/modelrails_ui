# frozen_string_literal: true

require "test_helper"

# No component emits a truncated class token.
#
# #259 replaced `peer-aria-invalid:ring-2 peer-aria-invalid:ring-danger` in the
# switch's TRACK by stripping the two class names out of that line and leaving
# the line itself behind, so the constant carried `"peer-peer-"`. Ruby
# concatenates adjacent string literals, and the remnant had no trailing space,
# so the rendered attribute contained ONE token:
# `peer-peer-peer-disabled:opacity-50`. A disabled switch lost its fade, and
# shipped that way in v0.23.0 (#263).
#
# Nothing saw it. The forced-colors gate asks whether something structural
# changes on invalid, which the switch's new border satisfies. The render tests
# assert that the classes they expect are PRESENT, never that nothing
# nonsensical is. And a phantom class generates no CSS, so it is silent.
#
# This checks one precise thing rather than validating every utility against
# Tailwind's grammar: a class token may not END in a separator. That is exactly
# the shape a find/replace remnant leaves, and no real utility has it — which
# keeps the rule free of the false positives a broader grammar would bring
# across ~90 templates.
class TestNoTruncatedClassTokens < Minitest::Test
  TEMPLATES = File.expand_path("../lib/generators/modelrails_ui/add/templates", __dir__)

  # `peer-peer-`, `hover:` — a prefix with nothing after it.
  TRUNCATED = /[-:]\z/

  def test_no_component_emits_a_truncated_class_token
    offenders = []

    Dir.glob("#{TEMPLATES}/*/*.rb.tt").sort.each do |path|
      component = File.basename(File.dirname(path))

      File.read(path).scan(/"([^"\n]*)"/).flatten.each do |literal|
        # Exclude what is not a class list. `": "` catches inline CSS and prose
        # alike ("flex: 1", "Date format: %{pattern}") — a class list never has
        # a space after a colon. Interpolated strings are built at render time.
        #
        # NOT by token count: `"peer-peer-"` is a SINGLE-token literal, so a
        # ">= 2 tokens" filter would have excluded the very bug this exists for.
        next if literal.include?('#{') || literal.include?("%{")
        next if literal.include?(": ") || literal.include?(";") || literal.match?(/[.,!?()]/)

        literal.split(/\s+/).reject(&:empty?).each do |token|
          # A bare separator is punctuation, not a truncated class.
          next unless token.match?(TRUNCATED) && token.match?(/[a-z]/i)

          offenders << "#{component}: #{token.inspect} in #{literal[0, 60].inspect}"
        end
      end
    end

    assert_empty offenders, <<~MSG
      These class tokens are truncated. A phantom class generates no CSS, so it
      ships silently — and with no trailing space it welds itself onto the next
      class and takes that one out too, which is how a disabled switch lost its
      fade (#263):

        #{offenders.join("\n  ")}
    MSG
  end

  # A regex that matches nothing asserts nothing.
  def test_recognises_a_truncated_token
    assert_match TRUNCATED, "peer-peer-"
    assert_match TRUNCATED, "hover:"
    refute_match TRUNCATED, "peer-disabled:opacity-50"
    refute_match TRUNCATED, "aria-invalid:[&::-moz-range-track]:border-danger"
    refute_match TRUNCATED, "-mt-1.5"
  end
end
