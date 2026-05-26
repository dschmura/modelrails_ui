# frozen_string_literal: true

require "active_support/core_ext/string/inflections"

module ViewPrimitives
  module ComponentHelper
    #   <%= ui :button, variant: :outline do %>Click<% end %>
    def ui(name, *, **, &)
      klass = "UI::#{name.to_s.camelize}Component".safe_constantize

      unless klass
        raise ViewPrimitives::ComponentNotFoundError,
          "Component `UI::#{name.to_s.camelize}Component` not found. " \
          "Run `rails g view_primitives:add #{name}` to generate it."
      end

      render(klass.new(*, **), &)
    end
  end
end
