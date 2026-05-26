# frozen_string_literal: true

module ViewPrimitives
  module Generators
    module Components
      TEMPLATE_ROOT = File.expand_path("add/templates", __dir__)

      # Stimulus controllers not colocated with the component template directory.
      EXTRA_STIMULUS = {
        "alert_dialog" => {source: "dialog/dialog_controller.js", name: "dialog"}
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
