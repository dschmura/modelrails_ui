# frozen_string_literal: true

require_relative "modelrails_ui/version"
require_relative "modelrails_ui/class_helper"
require_relative "modelrails_ui/component_helper"

module ModelrailsUi
  class Error < StandardError; end
  class ComponentNotFoundError < Error; end
end

require_relative "modelrails_ui/railtie" if defined?(Rails::Railtie)
