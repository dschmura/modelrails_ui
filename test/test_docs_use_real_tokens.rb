# frozen_string_literal: true

require "test_helper"

# Component docs are the first thing a developer or an AI agent copies, and a class
# that does not exist fails silently: no error, no warning, just an element with no
# styling (#192).
#
# The gem was seeded from shadcn/ui, and its token vocabulary came along in the
# prose long after the code stopped using it — `text-muted-foreground` alone had
# drifted into six component docs.
#
# This is a DENYLIST, which is the unusual choice here, so: the permitted set is all
# of Tailwind plus every token this gem defines, which is not enumerable in a test.
# The *foreign* vocabulary is finite and known, so it is the side worth naming. A
# phantom token outside this list still slips through — the gate narrows the hole
# rather than closing it, and that limit is the reason to keep the list growing
# whenever another is found.
class TestDocsUseRealTokens < Minitest::Test
  DOCS = File.expand_path("../docs/components", __dir__)

  # shadcn/ui semantic tokens. This design system uses surface/text/interactive
  # names instead — see docs/design-tokens.md.
  FOREIGN = %w[
    text-muted-foreground bg-muted text-foreground bg-background
    bg-card text-card-foreground bg-popover text-popover-foreground
    bg-primary text-primary-foreground bg-secondary text-secondary-foreground
    bg-accent text-accent-foreground bg-destructive text-destructive-foreground
    border-input ring-ring
  ].freeze

  def test_component_docs_carry_no_shadcn_tokens
    offenders = Dir.glob("#{DOCS}/*.md").sort.flat_map do |path|
      doc = File.basename(path)
      src = File.read(path)

      FOREIGN.filter_map do |token|
        # Word boundary on both sides: `bg-primary` must not match `bg-primary-800`,
        # which is a real Tailwind palette class.
        next unless src.match?(/(?<![\w-])#{Regexp.escape(token)}(?![\w-])/)

        "#{doc}: #{token}"
      end
    end

    assert_empty offenders, <<~MSG
      component docs reference tokens this design system does not define:
        #{offenders.join("\n  ")}

      These are shadcn/ui names. Use the surface/text/interactive tokens instead;
      docs/design-tokens.md lists them. A class that does not exist renders
      unstyled rather than failing, so nothing else catches this.
    MSG
  end
end
