# frozen_string_literal: true

module UI
  class SpinnerComponent < ApplicationComponent
    BASE = "inline-block animate-spin rounded-full border-2 border-current border-t-transparent"

    SIZES = {
      sm: "size-4",
      default: "size-6",
      lg: "size-10"
    }.freeze

    def initialize(size: :default, **html_attrs)
      @size = size.to_sym
      @extra_class = html_attrs.delete(:class)
      @html_attrs = html_attrs
    end

    def call
      content_tag(:span,
        content_tag(:span, "Loading...", class: "sr-only"),
        class: cn(BASE, SIZES.fetch(@size, SIZES[:default]), @extra_class),
        role: "status",
        **@html_attrs)
    end
  end
end
