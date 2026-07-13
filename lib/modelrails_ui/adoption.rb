# frozen_string_literal: true

require "yaml"
require "generators/modelrails_ui/components"
require_relative "adoption/scenarios"
require_relative "adoption/adapter_map"
require_relative "adoption/usage"
require_relative "adoption/audit_coverage"

module ModelrailsUi
  # Composes the units into a per-component adoption report, honoring the
  # fork-local `.modelrails_ui/adoption.yml` (adapters + suppress). Report-only;
  # the :strict rake variant turns blind_spots into a non-zero exit.
  module Adoption
    Components = ModelrailsUi::Generators::Components
    GEM_PREVIEWS = File.expand_path(
      "../generators/modelrails_ui/lookbook/templates/previews/ui", __dir__
    ).freeze

    # Candidate host roots for the audit-coverage inputs (fork-resilient: first
    # that exists wins), mirroring Usage's HOST_VIEW_DIRS probe pattern.
    #
    # HOST_PREVIEW_DIRS matters because a host's live previews DRIFT from the
    # gem's shipped templates the moment a fork edits scenarios — the gem's
    # {default, large} for dialog vs. a real host's {basic,
    # confirm_destructive, with_form}. M (the denominator) must come from
    # whichever scenarios the host's own specs actually visit, or coverage
    # never intersects and a fully-audited component (N == M) is misreported
    # as a 0/2 blind spot. GEM_PREVIEWS is the fallback ONLY for a host that
    # ships no previews of its own — never a substitute for a host that has
    # drifted.
    HOST_PREVIEW_DIRS = [
      "spec/components/previews/ui", "test/components/previews/ui", "app/components/previews/ui"
    ].freeze
    HOST_SPEC_DIRS = ["spec/system/ui", "test/system/ui"].freeze

    module_function

    def report(app_root:)
      cfg = load_config(app_root)
      adapters = AdapterMap.merged(normalize_adapters(cfg["adapters"]))
      suppress = (cfg["suppress"] || {}).keys.map(&:to_s)

      usage = Usage.new(app_root: app_root, adapter_map: adapters)
      coverage = AuditCoverage.new(
        specs_root: resolve_specs_root(app_root), previews_root: resolve_previews_root(app_root)
      )

      rows = Components.supported.map do |c|
        {component: c, adopted: usage.classify(c), audited: coverage.cover(c)}
      end

      blind_spots = rows
        .reject { |r| suppress.include?(r[:component]) }
        .select { |r| adopted?(r) && under_audited?(r) }

      {rows: rows, blind_spots: blind_spots,
       adapter_advisories: unmatched_adapters(adapters, rows)}
    end

    def render_markdown(report, verbose: false)
      out = "## Component adoption\n\n#{summary_line(report[:rows])}\n\n"
      out << "### Blind spots — adopted but under-audited (start here)\n\n"
      if report[:blind_spots].empty?
        out << "None. 🎉\n\n"
      else
        report[:blind_spots].each { |r| out << blind_spot_line(r) }
        out << "\n"
      end
      report[:adapter_advisories].each do |name|
        out << "> advisory: adapter `#{name}` matched no call sites — stale override?\n"
      end
      out << full_table(report[:rows]) if verbose
      out << remedy_footer
      out
    end

    # The host's own live previews (what its specs actually visit) — the
    # gem's shipped templates are only a fallback for a host that ships none.
    def resolve_previews_root(app_root)
      HOST_PREVIEW_DIRS.map { |d| File.join(app_root, d) }.find { |p| Dir.exist?(p) } || GEM_PREVIEWS
    end

    # Same fork-resilient probe; degrades gracefully (AuditCoverage#cover
    # treats a missing specs_root as "no spec found", never a crash), so an
    # all-candidates-missing host just falls back to the first candidate path.
    def resolve_specs_root(app_root)
      candidates = HOST_SPEC_DIRS.map { |d| File.join(app_root, d) }
      candidates.find { |p| Dir.exist?(p) } || candidates.first
    end

    def load_config(app_root)
      path = File.join(app_root, ".modelrails_ui", "adoption.yml")
      File.exist?(path) ? (YAML.safe_load_file(path) || {}) : {}
    end

    # YAML shorthand `name: { helper: foo }` → typed `{kind: :helper, value: "foo"}`.
    def normalize_adapters(raw)
      (raw || {}).transform_values do |v|
        kind, value = v.first
        {kind: kind.to_sym, value: value}
      end
    end

    def adopted?(r) = ![:none, :unknown].include?(r[:adopted][:value])
    def under_audited?(r) = r[:audited][:m].positive? && r[:audited][:n] < r[:audited][:m]

    def unmatched_adapters(adapters, rows)
      by_component = rows.to_h { |r| [r[:component], r[:adopted][:value]] }
      adapters.keys.select { |name| by_component[name] == :none }
    end

    def summary_line(rows)
      counts = rows.group_by { |r| r[:adopted][:value] }.transform_values(&:length)
      "#{rows.length} components — #{counts.map { |k, v| "#{v} #{k}" }.join(", ")}"
    end

    def blind_spot_line(r)
      a = r[:audited]
      extra = a[:unresolved].positive? ? " (#{a[:unresolved]} unresolved)" : ""
      "- **#{r[:component]}** — #{r[:adopted][:value]}, #{a[:n]}/#{a[:m]} scenarios " \
        "audited → audit the remaining states#{extra}\n"
    end

    def full_table(rows)
      head = "\n### All components\n\n| Component | Adopted | Audited |\n|---|---|---|\n"
      head + rows.map { |r|
        "| #{r[:component]} | #{r[:adopted][:value]} | #{r[:audited][:n]}/#{r[:audited][:m]} |"
      }.join("\n") + "\n"
    end

    def remedy_footer
      "\n---\nFalse dead? add an `adapters:` entry or `suppress:` it in " \
        "`.modelrails_ui/adoption.yml`. Gate this in CI with " \
        "`rake modelrails_ui:adoption:strict`.\n"
    end
  end
end
