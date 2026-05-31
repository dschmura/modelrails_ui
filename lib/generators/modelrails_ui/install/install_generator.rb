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
          say "  ApplicationComponent already exists — ensure it defines a private " \
              "`cn(*classes)` helper (flatten + compact + join). See the generated template.", :yellow
        else
          template "application_component.rb.tt", target
        end
      end

      def create_inflection_initializer
        target = "config/initializers/modelrails_ui_inflections.rb"

        if File.exist?(File.join(destination_root, target))
          say "  #{target} already exists — skipping.", :yellow
        else
          copy_file "inflections.rb", target
        end
      end

      def create_css_variables
        if host_defines_design_tokens?
          say "  Host already defines modelrails_ui design tokens — skipping the token CSS " \
              "(your app owns the tokens; avoids duplicating @theme/.btn-*).", :yellow
          return
        end

        copy_file "modelrails_ui.css", css_dest_path
      end

      def inject_css_import
        return if host_defines_design_tokens? # host owns the tokens; nothing to import

        entry = tailwind_entry_path

        unless entry
          say "\n  Could not detect a Tailwind CSS entry point.", :yellow
          say "  Add this line to your main CSS file:\n"
          say "    @import \"#{css_import_path || "./modelrails_ui"}\";\n"
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
        # Match `@import "tailwindcss";` or `'tailwindcss'`, with or without the semicolon.
        anchor = /@import\s+["']tailwindcss["'];?[ \t]*\n/

        if entry_content.match?(anchor)
          inject_into_file entry, import_line, after: anchor
        else
          append_to_file entry, "\n#{import_line}"
        end
      end

      private

      # True when the host app already defines the modelrails_ui semantic tokens
      # (i.e. it IS the token source, like modelrails_base). In that case the gem
      # must not ship/import its own copy — that would duplicate the design system.
      def host_defines_design_tokens?
        entry = tailwind_entry_path
        return false unless entry

        File.read(File.join(destination_root, entry)).match?(/--color-(surface|interactive)\b/)
      end
    end
  end
end
