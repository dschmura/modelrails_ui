# frozen_string_literal: true

module ModelrailsUi
  module Generators
    module Components
      TEMPLATE_ROOT = File.expand_path("add/templates", __dir__)

      # Stimulus controllers not colocated with the component template directory.
      EXTRA_STIMULUS = {
        "alert_dialog" => {source: "dialog/modal_controller.js", name: "modal"},
        "drawer" => {source: "dialog/modal_controller.js", name: "modal"},
        "sheet" => {source: "dialog/modal_controller.js", name: "modal"},
        "tooltip" => {source: "popover/floating_controller.js", name: "floating"},
        "hover_card" => {source: "popover/floating_controller.js", name: "floating"},
        "context_menu" => {source: "dropdown_menu/menu_controller.js", name: "menu"},
        "menubar_menu" => {source: "dropdown_menu/menu_controller.js", name: "menu"},
        "gallery" => {source: "dialog/modal_controller.js", name: "modal"}
      }.freeze

      # Post-install instructions for components that require external dependencies.
      SETUP_NOTES = {
        "chart" => <<~TEXT,
          Chart requires Chart.js. Add it to your importmap:

            # config/importmap.rb
            pin "chart.js", to: "https://cdn.jsdelivr.net/npm/chart.js@4/+esm"

          Then use the component:

            ui :chart, type: :bar,
              labels: ["Jan", "Feb", "Mar"],
              datasets: [{ label: "Revenue", data: [100, 200, 150] }]
        TEXT
        "wysiwyg" => <<~TEXT
          WYSIWYG defaults to Trix (adapter: :trix). To use Trix, install ActionText:

            bundle add actiontext
            rails action_text:install

          To use Quill (adapter: :quill), add it to your importmap:

            # config/importmap.rb
            pin "quill", to: "https://esm.sh/quill@2"

          Also add Quill's stylesheet to your CSS entry point:

            @import url("https://esm.sh/quill@2/dist/quill.snow.css");

          Usage:

            ui :wysiwyg, name: "body"
            ui :wysiwyg, name: "body", adapter: :quill, placeholder: "Write something..."
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
