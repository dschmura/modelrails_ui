# frozen_string_literal: true

require "active_support/core_ext/string/inflections"

module ModelrailsUi
  module ComponentHelper
    #   <%= ui :button, variant: :outline do %>Click<% end %>
    def ui(name, *, **, &)
      klass = "UI::#{name.to_s.camelize}Component".safe_constantize

      unless klass
        raise ModelrailsUi::ComponentNotFoundError,
          "Component `UI::#{name.to_s.camelize}Component` not found. " \
          "Run `rails g modelrails_ui:add #{name}` to generate it."
      end

      render(klass.new(*, **), &)
    end
  end
end
