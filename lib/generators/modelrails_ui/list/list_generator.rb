# frozen_string_literal: true

require_relative "../components"

module ModelrailsUi
  module Generators
    class ListGenerator < Rails::Generators::Base
      desc "List available ModelrailsUi components and whether they are installed"

      def list_components
        say "\nModelrailsUi components:\n\n", :bold
        say "COMPONENT          STATUS"
        say "-" * 32

        Components.supported.each do |component|
          status = Components.installed?(component, destination_root) ? "installed" : "—"
          color = (status == "installed") ? :green : :cyan
          say format("%-18s %s", component, status), color
        end

        say "\nInstall: rails g modelrails_ui:add <name>\n", :cyan
      end
    end
  end
end
