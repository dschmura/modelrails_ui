# frozen_string_literal: true

module ModelrailsUi
  module Adoption
    # Classifies how the host app adopts a component, from host source only.
    # Precedence (first match wins): direct call > adapter seam > utility
    # standin > transitive (component-internal) > dynamic (unknown) > none.
    #
    # Two comment-stripped source variants are scanned, because the evidence
    # each check needs lives in different places:
    #   - `code`   — comments AND string literals stripped. `direct?`,
    #     `adapter_hit?`, and `dynamic_only?` all match bare Ruby tokens
    #     (`ui :name`, `render UI::XComponent`, `text_field`, `avatar_for`,
    #     `ui(var)`) that are never legitimately written inside a quoted
    #     string — so a string that merely *contains* one of those tokens
    #     (e.g. `data-hint="ui :carousel"`) must not count as adoption.
    #   - `markup`  — comments stripped, strings PRESERVED. The css_prefix
    #     utility-standin check needs this: a `.btn-` standin only ever shows
    #     up inside a quoted `class="btn-primary"` attribute, so stripping
    #     quoted content would blind that check to the exact evidence it
    #     needs.
    # ERB and Ruby comments are stripped from BOTH variants; a naive grep of
    # app/components inflates adoption ~10x (all doc-comment `ui :` lines).
    class Usage
      # Candidate host-code roots (fork-resilient: first that exists wins
      # per group). Views and helpers are separate groups — a fork may rename
      # app/views to app/frontend/views, but app/helpers is always additional,
      # not a substitute, so it must never be shadowed by app/views existing.
      HOST_VIEW_DIRS = ["app/views", "app/frontend/views"].freeze
      HOST_HELPER_DIRS = ["app/helpers"].freeze
      COMPONENT_DIRS = ["app/components/ui", "app/components"].freeze

      def initialize(app_root:, adapter_map:)
        @app_root = app_root
        @adapter_map = adapter_map
      end

      def classify(component)
        klass = component_class(component)

        host_view_code, host_view_markup = read_sources(HOST_VIEW_DIRS)
        host_helper_code, host_helper_markup = read_sources(HOST_HELPER_DIRS)
        host_code = host_view_code + host_helper_code
        host_markup = host_view_markup + host_helper_markup

        comp_code = read_sources(COMPONENT_DIRS).first

        return {value: :direct, detail: "ui/render call"} if direct?(component, klass, host_code)

        adapter = @adapter_map[component]
        if adapter && adapter_hit?(adapter, host_code, host_markup)
          return {value: :adapter, detail: adapter_detail(adapter)}
        end

        if adapter && adapter[:kind] == :css_prefix
          n = count(css_needle(adapter[:value]), host_markup)
          return {value: :utility_standin, detail: "via utility classes #{adapter[:value]} (#{n} uses)"} if n.positive?
        end

        return {value: :transitive, detail: "composed inside another component"} if direct?(component, klass, comp_code)
        return {value: :unknown, detail: "dynamic ui(var) invocation"} if dynamic_only?(component, host_code + comp_code)

        {value: :none, detail: "no reference found"}
      end

      private

      # UI.const_get("#{name.camelize}Component") — invert the real resolver.
      def component_class(component)
        "UI::#{component.split("_").map(&:capitalize).join}Component"
      end

      def direct?(component, klass, src)
        src.include?("ui :#{component}") ||
          src.include?("ui(:#{component}") ||
          src.match?(/render\s*\(?\s*#{Regexp.escape(klass)}\b/)
      end

      # :css_prefix is deliberately absent here — it never resolves to
      # :adapter. It always routes through the dedicated utility_standin
      # check below, which uses a dot-stripped needle (see #css_needle).
      #
      # :method/:helper match bare Ruby tokens (`f.text_area`, `avatar_for`)
      # that are never legitimately quoted, so they scan `code` (strings
      # stripped) like `direct?`. :partial is the opposite: a partial path
      # (`shared/_modal`) only ever appears inside a quoted `render` argument
      # — scanning `code` would blank that argument to `""` and the branch
      # could never match, silently misclassifying a partial-only host as
      # :none. It scans `markup` (strings preserved) instead, exactly like
      # the css_prefix utility-standin check does.
      def adapter_hit?(adapter, code, markup)
        case adapter[:kind]
        when :method then code.match?(/[.\s]#{Regexp.escape(adapter[:value])}\b/)
        when :partial then markup.include?(adapter[:value]) || markup.include?(adapter[:value].sub("_", ""))
        when :helper then code.match?(/\b#{Regexp.escape(adapter[:value])}\b/)
        else false
        end
      end

      # `ui(var)` is a genuine dynamic dispatch, but on its own it can't be
      # attributed to any one component — it could reach ANY of them. Requiring
      # the component's own name to also appear (as real code, not a stripped
      # comment or string literal) is what keeps a genuinely-absent component
      # (:none) distinct from one plausibly reachable through the dynamic call
      # (:unknown). `src` here is always the `code` variant — a component name
      # sitting inside a quoted string (e.g. a `data-hint="ui :carousel"`
      # attribute) must not count as evidence either.
      def dynamic_only?(component, src)
        src.match?(/\bui\(\s*[a-z_][a-z0-9_]*\s*\)/) && src.match?(/\b#{Regexp.escape(component)}\b/)
      end

      def adapter_detail(a) = "via #{a[:kind]} #{a[:value]}"

      def count(needle, src) = src.scan(needle).length

      # adapter_map values use a leading "." as a CSS-selector-style prefix
      # marker (".btn-"); raw HTML class attributes never contain the literal
      # dot, so strip it before searching rendered markup.
      def css_needle(value) = value.delete_prefix(".")

      # Read all source under the first existing dir per group and return
      # both stripped variants: [code, markup]. Comment-stripping happens
      # per-file, before concatenation, so a file missing a trailing newline
      # can never merge its last line with the next file's first line and
      # blind the line-anchored comment regex.
      def read_sources(candidate_dirs)
        dir = candidate_dirs.map { |d| File.join(@app_root, d) }.find { |p| Dir.exist?(p) }
        return ["", ""] unless dir

        raws = Dir.glob(File.join(dir, "**", "*.{rb,erb}")).map { |f| File.read(f) }
        [raws.sum("") { |src| strip_code(src) }, raws.sum("") { |src| strip_comments(src) }]
      end

      # Remove ERB comments and Ruby line comments so documentation examples
      # (e.g. a YARD `# ui :button` usage sample) never count as usage.
      def strip_comments(src)
        src.gsub(/<%#.*?%>/m, " ")     # ERB comments
          .gsub(/^\s*#.*$/, " ")       # Ruby line comments
      end

      # Comment-stripped, PLUS string literals blanked. A quoted string can
      # contain any token verbatim (e.g. `data-hint="ui :carousel"`) without
      # that being real Ruby/ERB code invoking the component — only the
      # code variant should ever feed direct?/adapter_hit?/dynamic_only?.
      def strip_code(src)
        strip_comments(src)
          .gsub(/"[^"]*"/, '""')
          .gsub(/'[^']*'/, "''")
      end
    end
  end
end
