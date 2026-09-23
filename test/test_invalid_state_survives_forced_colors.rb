# frozen_string_literal: true

require "test_helper"

# The invalid state has to survive forced-colors mode.
#
# This library already rules on the mechanism for FOCUS: "an offset outline,
# never a box-shadow ring — a ring is clipped by overflow:hidden ancestors and
# vanishes in forced-colors mode." The same was never applied to validity, so
# `aria-invalid:ring-2 ring-danger` carried the invalid state in fourteen
# components and disappeared for exactly the users who need it most (#258).
#
# A COLOUR change is not enough either, which is the subtle half. Forced-colors
# replaces author colours with the system palette, so a border that is 1px in
# both states reads identically whether the field is valid or not — swapping
# `border-border-strong` for `border-danger` conveys nothing there. The signal
# has to be structural: a border that appears, or thickens.
# This REPLACES test_invalid_ring_width.rb, which pinned that every invalid
# ring COLOUR had a ring WIDTH — a real bug twice (#112, #122), and a rule that
# can no longer fail now that no invalid state uses a ring at all. A gate that
# cannot fail is worse than no gate: it reads as coverage. The contract it was
# protecting — the invalid state is actually drawn — is kept here, on a
# mechanism that survives the display mode its users need.
class TestInvalidStateSurvivesForcedColors < Minitest::Test
  TEMPLATES = File.expand_path("../lib/generators/modelrails_ui/add/templates", __dir__)

  # A template declares a CONTROL's invalid state if it mentions aria-invalid
  # at all — as an attribute it sets, or as a Tailwind variant it styles.
  #
  # Not `ERROR = "…"` on its own: copy_component's ERROR styles the error
  # MESSAGE (a `<p role="alert">`), not a control, and an earlier draft of this
  # guard reported it as an offender. A component that has no invalid state to
  # convey cannot fail to convey it.
  DECLARES_INVALID = /aria-invalid/
  # Structural, so forced-colors keeps it: a border width, or an outline.
  STRUCTURAL_EDGE = /(?:aria-invalid:|aria-\[invalid=true\]:|peer-aria-invalid:)(?:\[&[^\]]*\]:)?border-\d|ERROR[^"]*"[^"]*\bborder-\d/
  # The mechanism that does not survive.
  RING = /(?:aria-invalid:|aria-\[invalid=true\]:|peer-aria-invalid:)ring-|ERROR[^"]*"[^"]*\bring-/

  # Templates that STYLE an invalid variant. A template that only sets
  # `aria-invalid="true"` is wiring, not styling: form_builder and form_field
  # put the attribute on a child control that draws its own state, and
  # radio_group and chip_group mark a GROUP whose error message carries the
  # visual. Asking those for a border would be asking the wrong object.
  STYLES_INVALID = /(?:aria-invalid:|aria-\[invalid=true\]:|peer-aria-invalid:)/

  def invalid_templates
    Dir.glob("#{TEMPLATES}/*/*.rb.tt").sort.select { |p| File.read(p).match?(DECLARES_INVALID) }
  end

  def styling_templates
    Dir.glob("#{TEMPLATES}/*/*.rb.tt").sort.select { |p| File.read(p).match?(STYLES_INVALID) }
  end

  # POSITIVE CONTROL — this file asserts two lists are empty, which a scan that
  # matches nothing also produces. These are the templates it claims to police.
  def test_it_sees_the_templates_that_declare_an_invalid_state
    assert_operator invalid_templates.size, :>=, 12,
      "only #{invalid_templates.size} templates were seen as declaring an invalid state — " \
      "the scan has stopped reading them, so both assertions below would pass on anything"
  end

  # The OTHER way to pass: delete the invalid styling instead of fixing it, and
  # the template leaves the population the structural check reads. That is not
  # hypothetical — converting the rings dropped range and switch to no invalid
  # state at all, and this file went green until the count was pinned.
  def test_no_component_passes_by_styling_nothing
    assert_operator styling_templates.size, :>=, 12,
      "only #{styling_templates.size} templates style an invalid variant. A component " \
      "that stops styling its invalid state disappears from the check below rather " \
      "than failing it, so the count is pinned: #{styling_templates.map { |p| File.basename(p) }.join(", ")}"
  end

  def test_no_invalid_state_is_carried_by_a_box_shadow_ring
    offenders = invalid_templates.select { |p| File.read(p).match?(RING) }
      .map { |p| p.delete_prefix("#{TEMPLATES}/") }

    assert_empty offenders, <<~MSG
      These carry the invalid state with a box-shadow ring, which is not painted in
      forced-colors mode:

        #{offenders.join("\n  ")}

      Use a border width the invalid state changes. The library already rules this way
      for focus; validity is the same argument.
    MSG
  end

  def test_every_invalid_state_changes_something_structural
    offenders = styling_templates.reject { |p| File.read(p).match?(STRUCTURAL_EDGE) }
      .map { |p| p.delete_prefix("#{TEMPLATES}/") }

    assert_empty offenders, <<~MSG
      These declare an invalid state but change no border width or outline, so in
      forced-colors mode — where the system repaints every colour — they are
      indistinguishable from a valid control:

        #{offenders.join("\n  ")}

      A colour swap alone is not a state change there.
    MSG
  end
end
