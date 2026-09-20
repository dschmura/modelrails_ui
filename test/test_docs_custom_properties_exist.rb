# frozen_string_literal: true

require "test_helper"

# A custom property that does not exist is inert: overriding it produces no error,
# no warning, and no effect. A consumer follows the docs, sets their brand colour,
# ships, and cannot work out why nothing changed (#193).
#
# Unlike the class-name gate next door, this one is DERIVED rather than a denylist:
# the stylesheet is the authority on which properties exist, so the permitted set is
# read straight out of it — every property it defines, plus every one it consumes
# through var() (Tailwind's own palette arrives that way).
#
# Scored only in CSS contexts — a declaration, a var() call, or a backticked token
# name in prose — so a CLI flag like `--force` in a shell block is not mistaken for
# a custom property.
class TestDocsCustomPropertiesExist < Minitest::Test
  CSS = File.expand_path(
    "../lib/generators/modelrails_ui/install/templates/modelrails_ui.css", __dir__
  )
  DOCS = [
    *Dir.glob(File.expand_path("../docs/*.md", __dir__)),
    *Dir.glob(File.expand_path("../docs/components/*.md", __dir__))
  ].freeze

  # Generator flags share the `--` spelling and get backticked in prose exactly as a
  # token does. A reviewed exception rather than a looser regex: dropping the
  # backtick rule would stop the gate seeing a token table, which is the main thing
  # it exists to catch.
  CLI_FLAGS = %w[--force --skip --quiet --pretend --verbose].freeze

  def known_properties
    src = File.read(CSS)
    defined_here = src.scan(/^\s*(--[a-z][a-z0-9-]*)\s*:/).flatten
    consumed_here = src.scan(/var\(\s*(--[a-z][a-z0-9-]*)/).flatten
    (defined_here + consumed_here).uniq.to_set
  end

  def test_every_custom_property_named_in_the_docs_exists
    known = known_properties
    offenders = DOCS.sort.flat_map do |path|
      doc = path.sub(%r{\A.*/docs/}, "")

      cited_properties(File.read(path))
        .reject { |prop| known.include?(prop) || CLI_FLAGS.include?(prop) }
        .uniq
        .map { |prop| "#{doc}: #{prop}" }
    end

    assert_empty offenders, <<~MSG
      docs name custom properties the stylesheet does not define:
        #{offenders.join("\n  ")}

      Overriding a property that does not exist is silent — no error, no effect.
      See docs/design-tokens.md for the real vocabulary.
    MSG
  end

  private

  # A declaration, a var() call, or a backticked token name. Anything else (a CLI
  # flag in a shell block, say) is not a custom-property citation.
  def cited_properties(src)
    src.scan(/^\s*(--[a-z][a-z0-9-]*)\s*:/).flatten +
      src.scan(/var\(\s*(--[a-z][a-z0-9-]*)/).flatten +
      src.scan(/`(--[a-z][a-z0-9-]*)`/).flatten
  end
end
