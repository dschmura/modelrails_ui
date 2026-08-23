# frozen_string_literal: true

require "test_helper"

# Tailwind silently ignores a class it cannot resolve — no warning, no build error, just
# a rule that never exists. So a component template referencing a custom utility the
# shipped stylesheet does not define fails ONLY in the host app, visually, long after.
#
# That is exactly how `focus-ring` shipped undefined to every install while being emitted
# by 47 templates: the design system's documented AAA focus treatment (a 2px offset
# outline) simply did not exist downstream, and components fell back to the browser
# default. Nothing in the suite could see it.
class TestShippedStylesheetCompleteness < Minitest::Test
  STYLESHEET = File.expand_path("../lib/generators/modelrails_ui/install/templates/modelrails_ui.css", __dir__)
  TEMPLATES = File.expand_path("../lib/generators/modelrails_ui/add/templates", __dir__)

  # Names the stylesheet defines: `@utility foo` blocks and `.foo { }` component rules.
  def defined_names
    css = File.read(STYLESHEET)
    (css.scan(/@utility\s+([a-z0-9-]+)/).flatten + css.scan(/^\s*\.([a-z][a-z0-9-]*)\s*\{/).flatten).to_set
  end

  # Custom (non-Tailwind) names a template can legitimately reference. Anything matching
  # this vocabulary MUST be shipped, because Tailwind will not generate it.
  CUSTOM_PREFIXES = %w[focus-ring btn- page-container prose- lexxy-].freeze

  def referenced_custom_names
    Dir.glob("#{TEMPLATES}/**/*").select { |f| File.file?(f) && f.match?(/\.(tt|erb|js)\z/) }
      .flat_map { |f| File.read(f).scan(/[\s"'`]([a-z][a-z0-9-]*)[\s"'`]/).flatten }
      .select { |n| CUSTOM_PREFIXES.any? { |p| p.end_with?("-") ? n.start_with?(p) : n == p } }
      .to_set
  end

  def test_every_custom_class_a_template_uses_is_shipped
    missing = (referenced_custom_names - defined_names).sort

    assert_empty missing, <<~MSG
      These custom classes are emitted by component templates but never defined in
      modelrails_ui.css, so Tailwind silently drops them in a host app:

        #{missing.join("\n  ")}

      Define them in lib/generators/modelrails_ui/install/templates/modelrails_ui.css.
    MSG
  end

  # The focus treatment is a stated invariant of the library ("an offset outline, never a
  # box-shadow ring — a ring is clipped by overflow:hidden ancestors and vanishes in
  # forced-colors mode"), so the shipped CSS must not contradict it.
  def test_no_shipped_class_uses_a_box_shadow_focus_ring
    offenders = File.read(STYLESHEET)
      .scan(/^\s*\.([a-z][a-z0-9-]*)\s*\{(.*?)^\s*\}/m)
      .select { |_name, body| body.match?(/focus(-visible)?:ring/) }
      .map(&:first)

    assert_empty offenders, <<~MSG
      These shipped classes use a box-shadow focus ring (focus:ring-* / focus-visible:ring-*):

        #{offenders.join(", ")}

      The library's rule is an offset outline via the focus-ring utility. A box-shadow
      ring is clipped by any overflow:hidden ancestor and vanishes entirely in
      forced-colors mode — both WCAG 2.4.7 failures. Use `@apply focus-ring`.
    MSG
  end

  # The 44px form-control floor is a named token (#142): registering it in
  # @theme inline gives consumers `min-h-input`, replacing the two legacy
  # spellings (`min-h-11` and `min-h-[var(--form-input-height)]`) that let the
  # AAA invariant drift apart. The token must reference --form-input-height,
  # never restate the value.
  def test_the_input_height_token_is_registered_as_a_theme_utility
    theme_block = File.read(STYLESHEET)[/@theme inline \{.*?\n\}/m]

    refute_nil theme_block, "no @theme inline block in the shipped stylesheet"
    assert_includes theme_block, "--min-height-input: var(--form-input-height);"
  end
end
