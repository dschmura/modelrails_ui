# frozen_string_literal: true

require "test_helper"
require "rails/generators"
require_relative "../lib/generators/modelrails_ui/add/add_generator"

# Shared Ruby modules are the SHARED_JS idea one asset kind over: a plain .rb.tt
# that several component templates depend on, copied once to a fixed destination.
# Without the registry, a non-component .rb.tt inside a component dir would fall
# through to the NON_COMPONENT_RB check and, unregistered, be misfiled into
# app/components/ui/ under its own name — or duplicated per declarer.
class TestSharedRbModules < Minitest::Test
  Components = ModelrailsUi::Generators::Components
  TEMPLATES = File.expand_path("../lib/generators/modelrails_ui/add/templates", __dir__)

  def test_registered_shared_rb_sources_exist_on_disk
    Components::SHARED_RB.each_value do |mods|
      mods.each { |m| assert_path_exists File.join(TEMPLATES, m.fetch(:source)) }
    end
  end

  def test_shared_rb_destinations_are_app_components_ui_paths
    Components::SHARED_RB.each_value do |mods|
      mods.each { |m| assert m.fetch(:dest).start_with?("app/components/ui/") }
    end
  end

  def test_modal_family_declares_the_chrome_module
    %w[dialog sheet drawer].each do |c|
      sources = Components::SHARED_RB.fetch(c).map { |m| m.fetch(:source) }

      assert_includes sources, "dialog/modal_chrome.rb.tt"
    end
  end

  # The misfile invariant, extended: every .rb.tt that is neither a *_component.rb.tt
  # nor claimed by NON_COMPONENT_RB must be claimed as a SHARED_RB source.
  def test_every_unclaimed_rb_tt_is_a_registered_shared_module
    shared_sources = Components::SHARED_RB.values.flatten.map { |m| m.fetch(:source) }.uniq
    on_disk = Dir.glob("#{TEMPLATES}/*/*.rb.tt")
      .reject { |p| File.basename(p).end_with?("_component.rb.tt") }
      .map { |p| p.delete_prefix("#{TEMPLATES}/") }
      .reject { |rel| Components::NON_COMPONENT_RB.key?(rel) }

    assert_equal on_disk.sort, (on_disk & shared_sources).sort,
      "unclaimed non-component .rb.tt would be misfiled: #{(on_disk - shared_sources).inspect}"
  end

  # Disjointness gate (#132): a source registered in BOTH registries would let
  # SHARED_RB silently win in copy_template_file's .rb.tt arm, turning the
  # NON_COMPONENT_RB entry into dead code while both misfile invariants stay
  # green.
  def test_shared_rb_and_non_component_rb_sources_are_disjoint
    shared_sources = Components::SHARED_RB.values.flatten.map { |m| m.fetch(:source) }
    overlap = shared_sources & Components::NON_COMPONENT_RB.keys

    assert_empty overlap, "sources registered in both SHARED_RB and NON_COMPONENT_RB: #{overlap.inspect}"
  end

  # Multi-declarer idempotency rests on every declarer agreeing where a shared
  # source lands; two dests for one source would make the second `add` write a
  # second copy, and two sources sharing a dest would make it overwrite.
  def test_shared_rb_source_to_dest_mapping_is_one_to_one
    pairs = Components::SHARED_RB.values.flatten.map { |m| [m.fetch(:source), m.fetch(:dest)] }.uniq

    pairs.group_by(&:first).each do |source, group|
      assert_equal 1, group.size, "#{source} is declared with multiple dests: #{group.map(&:last).inspect}"
    end
    pairs.group_by(&:last).each do |dest, group|
      assert_equal 1, group.size, "#{dest} is claimed by multiple sources: #{group.map(&:first).inspect}"
    end
  end
end

# The two-declarer sequence a real app hits: `add dialog` then `add sheet`.
# Thor no-ops the shared chrome only when the second render is byte-identical —
# an ERB drift between declarers would surface here as a conflict (#132). This
# pins the assumption for SHARED_RB and, by the same mechanism, SHARED_JS.
class TestSharedRbGeneratorIdempotency < Minitest::Test
  Components = ModelrailsUi::Generators::Components
  CHROME_DEST = Components::SHARED_RB.fetch("dialog")
    .find { |m| m.fetch(:source) == "dialog/modal_chrome.rb.tt" }.fetch(:dest)

  def run_add(component, root)
    out = StringIO.new
    # Empty stdin: a Thor conflict prompt must EOF-fail the test, never hang it.
    $stdin = StringIO.new
    orig_stdout, $stdout = $stdout, out
    ModelrailsUi::Generators::AddGenerator.start([component], destination_root: root)
    out.string
  ensure
    $stdout = orig_stdout
    $stdin = STDIN
  end

  def test_add_dialog_then_add_sheet_no_ops_on_the_shared_chrome
    root = Dir.mktmpdir
    run_add("dialog", root)
    chrome = File.join(root, CHROME_DEST)

    assert_path_exists chrome
    first = File.read(chrome)

    second_output = run_add("sheet", root)

    assert_equal first, File.read(chrome),
      "second declarer rewrote the shared chrome — declarers render different content"
    assert_match(/identical.*#{Regexp.escape(CHROME_DEST)}/o, second_output)
    refute_match(/conflict/, second_output)
  ensure
    FileUtils.remove_entry(root)
  end
end
