# frozen_string_literal: true

module ModelrailsUi
  module Generators
    module Components
      TEMPLATE_ROOT = File.expand_path("add/templates", __dir__)

      # Stimulus controllers not colocated with the component template directory.
      EXTRA_STIMULUS = {
        "drawer" => {source: "dialog/modal_controller.js", name: "modal"},
        "sheet" => {source: "dialog/modal_controller.js", name: "modal"},
        "tooltip" => {source: "popover/floating_controller.js", name: "floating"},
        "hover_card" => {source: "popover/floating_controller.js", name: "floating"},
        "context_menu" => {source: "dropdown_menu/menu_controller.js", name: "menu"},
        "menubar_menu" => {source: "dropdown_menu/menu_controller.js", name: "menu"},
        "gallery" => {source: "dialog/modal_controller.js", name: "modal"}
      }.freeze

      # Shared ES modules — plain modules, NOT Stimulus controllers. Some behaviour has to
      # be a single instance shared by every overlay (the top-layer helper below), which a
      # per-component controller copy cannot provide, so it ships as a module the
      # controllers import.
      #
      # `source` is the canonical copy in the owning component's template dir; `dir` is the
      # namespace it lands in under app/javascript/, which is also the importmap pin.
      # Every entry is enforced by test/test_shared_js_modules.rb — an unregistered `.js`
      # in a template dir would be silently dropped by the generator.
      TOP_LAYER = {source: "dropdown_menu/top_layer.js", dir: "overlays"}.freeze
      # Vendored third-party (cmdk's command-score, MIT — see the file header). Its own
      # namespace rather than `overlays`: it is a scoring utility, not an overlay concern,
      # and a host reading its importmap should be able to tell what it is.
      COMMAND_SCORE = {source: "command/command_score.js", dir: "search"}.freeze

      # Type-ahead + activedescendant movement, shared by the menu family. Lives in
      # dropdown_menu/ because the menu engine is its origin; namespaced `keyboard`
      # because it is movement logic, not a dropdown concern.
      KEYBOARD_NAV = {source: "dropdown_menu/keyboard_nav.js", dir: "keyboard"}.freeze

      SHARED_JS = {
        "dropdown_menu" => [TOP_LAYER, KEYBOARD_NAV],
        "context_menu" => [TOP_LAYER, KEYBOARD_NAV],
        "menubar" => [TOP_LAYER, KEYBOARD_NAV],
        "menubar_menu" => [TOP_LAYER, KEYBOARD_NAV],
        "popover" => [TOP_LAYER],
        "combobox" => [TOP_LAYER, KEYBOARD_NAV],
        "date_picker" => [TOP_LAYER],
        "timepicker" => [TOP_LAYER],
        "navigation_menu" => [TOP_LAYER],
        "mega_menu" => [TOP_LAYER],
        "command" => [COMMAND_SCORE, KEYBOARD_NAV]
      }.freeze

      # Shared Ruby modules — SHARED_JS, one asset kind over. A plain .rb.tt
      # several component templates include at render time, copied once to a
      # fixed destination. test/test_shared_rb_modules.rb pins the misfile
      # invariant.
      MODAL_CHROME = {source: "dialog/modal_chrome.rb.tt", dest: "app/components/ui/modal_chrome.rb"}.freeze

      SHARED_RB = {
        "dialog" => [MODAL_CHROME],
        "sheet" => [MODAL_CHROME],
        "drawer" => [MODAL_CHROME]
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
        "wysiwyg" => <<~TEXT,
          WYSIWYG defaults to Trix (adapter: :trix). To use Trix, install ActionText:

            bundle add actiontext
            rails action_text:install

          To use Quill (adapter: :quill), add it to your importmap:

            # config/importmap.rb
            pin "quill", to: "https://cdn.jsdelivr.net/npm/quill@2/+esm"

          Also add Quill's stylesheet to your CSS entry point:

            @import url("https://cdn.jsdelivr.net/npm/quill@2/dist/quill.snow.css");

          Usage:

            ui :wysiwyg, name: "body"
            ui :wysiwyg, name: "body", adapter: :quill, placeholder: "Write something..."
        TEXT
        "form_builder" => <<~TEXT
          Wire it up as your app's default form builder:

            # config/initializers/form_builder.rb
            Rails.application.config.to_prepare do
              ActionView::Base.default_form_builder = UI::FormBuilder
            end

          …or per form:

            form_with model: @user, builder: UI::FormBuilder

          This file is meant to be SUBCLASSED, not edited — re-running
          `rails g modelrails_ui:add form_builder` overwrites it. Put your
          customizations in a subclass (see the class header comment).
        TEXT
      }.freeze

      # Ruby templates that are NOT ViewComponents, routed by explicit map — the
      # SHARED_JS precedent, one asset kind over. An unmapped non-component .rb.tt
      # would be misfiled into app/components/ui/ by the generator's fallback;
      # test/test_form_builder_registry.rb pins the invariant.
      NON_COMPONENT_RB = {
        "form_builder/form_builder.rb.tt" => "app/form_builders/ui/form_builder.rb"
      }.freeze

      # Install-status markers for components whose primary file is not
      # app/components/ui/<name>_component.rb (see primary_path below).
      PRIMARY_PATHS = {
        "form_builder" => "app/form_builders/ui/form_builder.rb",
        "form_draft" => "app/views/shared/_form_draft_notice.html.erb"
      }.freeze

      # Components that hard-require sibling components at render time. The add
      # generator installs these transitively — without this, `add form_builder`
      # in a bare app installs a file that NameErrors on the first field.
      DEPENDENCIES = {
        "form_builder" => %w[form_field input textarea file_input select label error_summary]
      }.freeze

      # Transitive dependency expansion, input order first, no duplicates.
      def self.expand(names)
        seen = []
        queue = names.dup
        while (name = queue.shift)
          next if seen.include?(name)

          seen << name
          queue.concat(DEPENDENCIES.fetch(name, []))
        end
        seen
      end

      def self.supported
        @supported ||= Dir.children(TEMPLATE_ROOT).sort.freeze
      end

      def self.primary_path(component)
        PRIMARY_PATHS.fetch(component) { "app/components/ui/#{component}_component.rb" }
      end

      def self.installed?(component, root)
        File.exist?(File.join(root, primary_path(component)))
      end
    end
  end
end
