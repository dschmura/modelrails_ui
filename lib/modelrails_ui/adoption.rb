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

    module_function

    def report(app_root:)
      cfg = load_config(app_root)
      adapters = AdapterMap.merged(normalize_adapters(cfg["adapters"]))
      suppress = (cfg["suppress"] || {}).keys.map(&:to_s)

      usage = Usage.new(app_root: app_root, adapter_map: adapters)
      coverage = AuditCoverage.new(
        specs_root: File.join(app_root, "spec/system/ui"), previews_root: GEM_PREVIEWS
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
