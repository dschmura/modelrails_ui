# frozen_string_literal: true

require_relative "scenarios"

module ModelrailsUi
  module Adoption
    # Computes N/M scenario coverage from a component's system spec. THE
    # highest-risk unit: the 0b specs visit the ViewComponent preview host
    # (/rails/view_components/ui/<name>_component/<scenario>), and roughly a
    # quarter of those visits are interpolated — and they cluster in the
    # BEST-audited specs (many scenarios, a shared base path, a loop). A naive
    # regex under-counts exactly the flagship components: a false
    # "under-audited" blind spot on the components that are audited the most
    # thoroughly, which is the cardinal sin this tool exists to avoid.
    #
    # Two real interpolation shapes are resolved statically:
    #   - loop:     `visit ".../#{scenario}"` inside a `.each do |scenario|`
    #     driven by a `%w[...]` literal OR a hash literal (symbol-key
    #     `default:` or string-rocket-key `"default" =>` — both appear in
    #     modelrails_base's real specs, e.g. alert/badge use string-rocket
    #     keys, popover/dialog/kbd use %w[]).
    #   - constant: a file-level `CONST = "…/x_component[/scenario]"` string,
    #     referenced either interpolated inside a string (`"#{CONST}/off"`)
    #     or, when a second constant is built from the first
    #     (`SCEN = "#{CONST}/off"`), referenced BARE as the whole `visit`
    #     argument (`visit SCEN`) — the shape found in range_component_spec.rb.
    #     Constant resolution is transitive so a constant built from another
    #     constant still resolves.
    #
    # Anything that still can't be pinned to a literal scenario after that —
    # e.g. a loop driven by a runtime method call — is labeled `unresolved`
    # and counted separately. It NEVER falls back to a silent 0: a `visit`
    # line this file can't statically resolve always shows up somewhere in
    # the returned hash.
    class AuditCoverage
      VISIT = %r{/rails/view_components/ui/(?<comp>\w+?)_component/(?<scen>[^"'/]+)}
      CONST_ASSIGN = /^\s*([A-Z][A-Z0-9_]*)\s*=\s*"([^"]*)"/
      BARE_VISIT = /visit\s+([A-Z][A-Z0-9_]*)\b/

      def initialize(specs_root:, previews_root:)
        @specs_root = specs_root
        @previews_root = previews_root
      end

      def cover(component)
        m = Scenarios.for(component, previews_root: @previews_root)
        src = spec_source(component)
        return {n: 0, m: m.length, unresolved: 0} if src.nil?

        visited, unresolved = extract(src, component)
        {n: (visited & m).length, m: m.length, unresolved: unresolved}
      end

      private

      def spec_source(component)
        path = Dir.glob(File.join(@specs_root, "**", "#{component}*spec.rb")).first
        path && File.read(path)
      end

      # Returns [Array<String> resolved scenario names, Integer unresolved count].
      def extract(src, component)
        consts = resolve_constants(src)
        resolved = []
        unresolved = 0

        src.each_line do |raw_line|
          line = raw_line.sub(/^\s*#.*/, "") # drop full-line comments only
          next unless line.include?("visit")

          expanded = expand_constants(line, consts)

          if (hit = expanded.match(VISIT)) && hit[:comp] == component
            scen = hit[:scen]
            if scen.include?("\#{")
              names = loop_names(src, scen)
              names.empty? ? (unresolved += 1) : resolved.concat(names)
            else
              resolved << scen
            end
          elsif (bare = line.match(BARE_VISIT))
            unresolved += 1 unless resolve_bare_constant(bare[1], consts, component, resolved)
          elsif expanded.include?("\#{")
            unresolved += 1 # an interpolated visit we could not tie to this component
          end
        end

        [resolved.uniq, unresolved]
      end

      # `visit CONST_NAME` — the whole argument is a bare constant reference,
      # no quotes on the `visit` line itself (so it carries no literal path
      # substring and no `#{` for the generic fallback to catch). Resolves
      # via the already-transitively-resolved `consts` map.
      #
      # Returns true if handled (resolved-and-counted, or determined
      # irrelevant to this component); false if it should count as
      # unresolved.
      def resolve_bare_constant(name, consts, component, resolved)
        value = consts[name]
        return false if value.nil? # unknown constant in this component's own spec: flag it

        hit = value.match(VISIT)
        if hit && hit[:comp] == component && !value.include?("\#{")
          resolved << hit[:scen]
          return true
        end

        # depends on something we couldn't resolve, or targets a component but
        # mismatched/unresolved -> unresolved; otherwise resolves cleanly to
        # something unrelated to the preview host -> not our concern.
        !(value.include?("\#{") || value.include?("view_components/ui"))
      end

      # PREVIEW = "…/switch_component"  →  {"PREVIEW" => "…/switch_component"}.
      # Resolved TRANSITIVELY: a constant built from another constant
      # (`SCEN = "#{PREVIEW}/off"`) still ends up fully expanded, bounded by
      # the number of constants so no pathological input can loop forever.
      def resolve_constants(src)
        consts = src.scan(CONST_ASSIGN).to_h
        (consts.size + 1).times do
          changed = false
          consts.each do |name, val|
            next unless val.include?("\#{")

            new_val = consts.reduce(val) { |acc, (n, v)| (n == name) ? acc : acc.gsub("\#{#{n}}", v) }
            next if new_val == val

            consts[name] = new_val
            changed = true
          end
          break unless changed
        end
        consts
      end

      def expand_constants(line, consts)
        consts.reduce(line) { |acc, (name, val)| acc.gsub("\#{#{name}}", val) }
      end

      # For `visit ".../#{scenario}"` inside `.each do |scenario|`, read the
      # keys of the driving literal (`%w[...]` or a hash, either key style).
      def loop_names(src, scen_expr)
        var = scen_expr[/#\{(\w+)\}/, 1]
        return [] unless var

        if (m = src.match(/%w\[([^\]]+)\]\s*\.each\s+do\s*\|\s*#{var}\b/m))
          return m[1].split
        end
        if (m = src.match(/\{(.+?)\}\s*\.each\s+do\s*\|\s*#{var}\b/m))
          return hash_keys(m[1])
        end
        []
      end

      # Symbol-key (`default:`) and string-rocket-key (`"default" =>` /
      # `'default' =>`) hash literals both appear in real specs.
      def hash_keys(body)
        keys = body.scan(/"([^"]+)"\s*=>/).flatten
        return keys if keys.any?

        keys = body.scan(/'([^']+)'\s*=>/).flatten
        return keys if keys.any?

        body.scan(/(\w+):/).flatten
      end
    end
  end
end
