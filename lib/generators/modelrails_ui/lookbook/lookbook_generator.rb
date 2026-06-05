# frozen_string_literal: true

module ModelrailsUi
  module Generators
    # Installs Lookbook living documentation for the modelrails_ui components:
    # a preview layout (loads the host's compiled Tailwind + importmap so previews
    # render styled + interactive), a dev-only config initializer, and
    # ViewComponent::Preview classes for the solid components.
    #
    #   rails g modelrails_ui:lookbook
    class LookbookGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      def copy_preview_layout
        copy_file "component_preview.html.erb", "app/views/layouts/component_preview.html.erb"
      end

      # Self-contained light/dark toggle for the preview host (used by the
      # toggle button in component_preview.html.erb). Auto-registered by
      # stimulus-loading's eagerLoadControllersFrom as the `preview-theme` controller.
      def copy_preview_theme_controller
        copy_file "preview_theme_controller.js", "app/javascript/controllers/preview_theme_controller.js"
      end

      def copy_initializer
        copy_file "lookbook.rb", "config/initializers/modelrails_ui_lookbook.rb"
      end

      def copy_previews
        directory "previews", "spec/components/previews"
      end

      def print_setup_notes
        say "\n  Lookbook previews installed. To finish wiring it up:", :green
        say "    1. Add Lookbook to your Gemfile (development group):"
        say "         group :development do", :cyan
        say "           gem \"lookbook\"", :cyan
        say "         end", :cyan
        say "    2. Mount it in config/routes.rb (development only):"
        say "         mount Lookbook::Engine, at: \"/lookbook\" if Rails.env.development?", :cyan
        say "    3. bundle install, restart the server, open /lookbook"
        say "  Previews live in spec/components/previews/ui/ — edit or add freely.\n", :cyan
      end
    end
  end
end
