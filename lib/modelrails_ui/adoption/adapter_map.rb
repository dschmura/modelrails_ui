# frozen_string_literal: true

module ModelrailsUi
  module Adoption
    # The typed adapter map: how the host reaches a component WITHOUT a literal
    # `ui :name` call. Each entry declares its match-kind so the resolver knows
    # how to look (a form-builder method, a rendered partial, a helper, or a CSS
    # standin). Shipped defaults describe modelrails_base's wiring; a fork
    # extends/overrides per key via `.modelrails_ui/adoption.yml`.
    module AdapterMap
      DEFAULTS = {
        "input" => {kind: :method, value: "text_field"},
        "textarea" => {kind: :method, value: "text_area"},
        "file_input" => {kind: :method, value: "file_field"},
        "dialog" => {kind: :partial, value: "shared/_modal"},
        "avatar" => {kind: :helper, value: "avatar_for"},
        "button" => {kind: :css_prefix, value: ".btn-"}
      }.freeze

      module_function

      def merged(overrides)
        DEFAULTS.merge(overrides || {}) do |_key, _default, override|
          override
        end
      end
    end
  end
end
