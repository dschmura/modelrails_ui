# frozen_string_literal: true

module ModelrailsUi
  module Adoption
    # Lists a component's auditable preview scenarios — the sibling
    # `<scenario>.html.erb` templates under `<name>_component_preview/`,
    # excluding `dont_*` anti-pattern examples (counter-examples, not states
    # a component should be audited in). This is the denominator M for the
    # adoption report's `audited` column and the scenario source the Part-1
    # completeness gate exposes.
    module Scenarios
      module_function

      def for(component, previews_root:)
        dir = File.join(previews_root, "#{component}_component_preview")
        return [] unless File.directory?(dir)

        Dir.children(dir)
          .select { |f| f.end_with?(".html.erb") }
          .map { |f| File.basename(f, ".html.erb") }
          .reject { |name| name.start_with?("dont_") }
          .sort
      end
    end
  end
end
