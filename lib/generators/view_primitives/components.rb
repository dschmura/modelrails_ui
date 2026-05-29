# frozen_string_literal: true

module ViewPrimitives
  module Generators
    module Components
      TEMPLATE_ROOT = File.expand_path("add/templates", __dir__)

      # Stimulus controllers not colocated with the component template directory.
      EXTRA_STIMULUS = {
        "alert_dialog" => {source: "dialog/dialog_controller.js", name: "dialog"}
      }.freeze

      # Post-install instructions for components that require external dependencies.
      SETUP_NOTES = {
        "chart" => <<~TEXT
          Chart requires Chart.js. Add it to your importmap:

            # config/importmap.rb
            pin "chart.js", to: "https://esm.sh/chart.js@4"

          Then use the component:

            ui :chart, type: :bar,
              labels: ["Jan", "Feb", "Mar"],
              datasets: [{ label: "Revenue", data: [100, 200, 150] }]
        TEXT
      }.freeze

      def self.supported
        @supported ||= Dir.children(TEMPLATE_ROOT).sort.freeze
      end

      def self.primary_path(component)
        "app/components/ui/#{component}_component.rb"
      end

      def self.installed?(component, root)
        File.exist?(File.join(root, primary_path(component)))
      end
    end
  end
end
