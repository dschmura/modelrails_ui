# frozen_string_literal: true

module ModelrailsUi
  class Railtie < Rails::Railtie
    initializer "modelrails_ui.inflections" do
      ActiveSupport::Inflector.inflections(:en) { |inflect| inflect.acronym "UI" }
    end

    generators do
      %w[install add list].each do |gen|
        require "generators/modelrails_ui/#{gen}/#{gen}_generator"
      end
    end

    initializer "modelrails_ui.component_helper" do
      %i[action_view action_mailer].each do |hook|
        ActiveSupport.on_load(hook) { include ModelrailsUi::ComponentHelper }
      end
    end
  end
end
