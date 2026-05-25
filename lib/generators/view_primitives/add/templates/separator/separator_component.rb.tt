# frozen_string_literal: true

module UI
  class SeparatorComponent < ApplicationComponent
    ORIENTATIONS = {
      horizontal: "bg-border h-px w-full shrink-0",
      vertical: "bg-border h-full w-px shrink-0"
    }.freeze

    def initialize(orientation: :horizontal, decorative: true, **html_attrs)
      @orientation = orientation.to_sym
      @decorative = decorative
      @extra_class = html_attrs.delete(:class)
      @html_attrs = html_attrs
    end

    def call
      content_tag(:div, nil,
        role: (@decorative ? "none" : "separator"),
        "aria-orientation": @orientation.to_s,
        class: cn(ORIENTATIONS[@orientation], @extra_class),
        **@html_attrs)
    end
  end
end
