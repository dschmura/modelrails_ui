# frozen_string_literal: true

require "test_helper"

# Tailwind's preflight sets `list-style: none` on `ul`/`ol`, and Safari/VoiceOver
# drop the implicit list role once the marker is gone: no "list, N items" on
# entry, no set position per row, and the list vanishes from the rotor. axe has
# no rule for this browser quirk, so a green audit is not evidence either way —
# a text-level guard is the only thing that can hold the line.
#
# The guard ENUMERATES: it derives the set of list-emitting templates from the
# templates themselves and fails on any member it cannot classify, so a new
# component cannot reopen the gap by simply not being listed here.
class TestListsCarryTheListRole < Minitest::Test
  TEMPLATE_ROOT = File.expand_path("../lib/generators/modelrails_ui/add/templates", __dir__)

  # A list that KEEPS its marker keeps its implicit role and needs no override.
  # Each entry has to name the utility that restores the marker, so the next
  # sweep can re-check the claim instead of trusting the exemption.
  EXEMPT = {
    "error_summary" => "list-disc list-inside"
  }.freeze

  LIST_CALL = /content_tag\(:(?:ul|ol)\b/
  ROLE_LIST = /(?:role:\s*"list"|"role"\s*=>\s*"list")/

  def templates
    Dir[File.join(TEMPLATE_ROOT, "*", "*_component.rb.tt")].sort
  end

  def name_of(file) = File.basename(file, "_component.rb.tt")

  # Comment lines mention `<ul>`/`<ol>` in prose; only real calls count.
  def emitters
    templates.filter_map do |file|
      body = File.read(file)
      sites = body.lines.grep_v(/^\s*#/).join.scan(LIST_CALL).length
      [name_of(file), file, body, sites] if sites.positive?
    end
  end

  def test_every_list_emitting_template_restores_the_list_role
    offenders = emitters.reject { |name, _, body, sites|
      EXEMPT.key?(name) || body.scan(ROLE_LIST).length >= sites
    }

    assert_empty offenders.map(&:first),
      "emits <ul>/<ol> without restoring role=\"list\" (Safari/VoiceOver drops list " \
      "semantics when preflight removes the marker): #{offenders.map(&:first).join(", ")}"
  end

  # An exemption is a claim about the markup, so hold it to the markup: the
  # component must actually restore the marker it says it does.
  def test_exempt_templates_really_do_keep_their_marker
    EXEMPT.each do |name, utility|
      file = templates.find { |f| name_of(f) == name }

      refute_nil file, "EXEMPT names a template that does not exist: #{name}"
      assert_includes File.read(file), utility,
        "#{name} is exempt because of #{utility.inspect}, but does not apply it"
    end
  end

  def test_exempt_templates_still_emit_a_list
    exempt_emitters = emitters.map(&:first) & EXEMPT.keys

    assert_equal EXEMPT.keys.sort, exempt_emitters.sort,
      "EXEMPT names a template that emits no list — drop the stale entry"
  end
end
