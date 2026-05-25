# frozen_string_literal: true

module UI
  class BannerComponent < ApplicationComponent
    BASE = "flex items-center gap-3 rounded-lg border p-4 text-sm"

    VARIANTS = {
      default:     "bg-background text-foreground",
      info:        "border-blue-200 bg-blue-50 text-blue-900",
      warning:     "border-yellow-200 bg-yellow-50 text-yellow-900",
      destructive: "border-destructive/40 bg-destructive/10 text-destructive",
      success:     "border-green-200 bg-green-50 text-green-900"
    }.freeze

    def initialize(message = nil, variant: :default, **html_attrs)
      @message = message || html_attrs.delete(:message) || html_attrs.delete(:label)
      @variant = variant.to_sym
      @extra_class = html_attrs.delete(:class)
      @html_attrs = html_attrs
    end

    def call
      content_tag(:div,
        content.presence || @message,
        class: cn(BASE, VARIANTS.fetch(@variant, VARIANTS[:default]), @extra_class),
        **@html_attrs)
    end
  end
end
