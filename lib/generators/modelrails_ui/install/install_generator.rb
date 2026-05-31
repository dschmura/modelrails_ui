# frozen_string_literal: true

require_relative "../detector"

module ModelrailsUi
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include Detector

      source_root File.expand_path("templates", __dir__)

      def verify_ui_inflection
        return if "ui/button".camelize == "UI::ButtonComponent"

        say "\n  Warning: ActiveSupport inflection for `UI` is not configured.", :yellow
        say "  ModelrailsUi expects `ui/button` to resolve to `UI::ButtonComponent`.", :yellow
        say "  The gem registers this automatically — restart the Rails server if you just installed.\n", :yellow
      end

      def create_application_component
        target = "app/components/application_component.rb"

        if File.exist?(File.join(destination_root, target))
          say "  ApplicationComponent already exists. Add `include ModelrailsUi::ClassHelper` manually.", :yellow
        else
          template "application_component.rb.tt", target
        end
      end

      def create_css_variables
        copy_file "modelrails_ui.css", css_dest_path
      end

      def inject_css_import
        entry = tailwind_entry_path

        unless entry
          say "\n  Could not detect a Tailwind CSS entry point.", :yellow
          say "  Add this line to your main CSS file:\n"
          say "    @import \"./modelrails_ui\";\n"
          say "  Common locations: app/assets/tailwind/application.css, " \
              "app/assets/stylesheets/application.tailwind.css, app/javascript/application.css\n", :cyan
          return
        end

        entry_content = File.read(File.join(destination_root, entry))

        if entry_content.include?("modelrails_ui")
          say "  #{entry} already imports modelrails_ui — skipping.", :yellow
          return
        end

        import_line = "@import \"#{css_import_path}\";\n"

        if entry_content.include?('@import "tailwindcss"')
          inject_into_file entry, import_line, after: "@import \"tailwindcss\"\n"
        elsif entry_content.include?("@import 'tailwindcss'")
          inject_into_file entry, import_line, after: "@import 'tailwindcss'\n"
        else
          append_to_file entry, "\n#{import_line}"
        end
      end
    end
  end
end
