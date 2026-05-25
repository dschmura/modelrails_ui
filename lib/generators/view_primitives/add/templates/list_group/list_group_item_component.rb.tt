# frozen_string_literal: true

module UI
  class ListGroupItemComponent < ApplicationComponent
    BASE = "flex items-center justify-between px-4 py-3 text-sm"

    VARIANTS = {
      default: "text-foreground hover:bg-muted",
      active:  "bg-primary text-primary-foreground",
      muted:   "text-muted-foreground hover:bg-muted"
    }.freeze

    def initialize(label = nil, href: nil, active: false, variant: :default, **html_attrs)
      @label = label || html_attrs.delete(:label)
      @href = href
      @variant = active ? :active : variant.to_sym
      @extra_class = html_attrs.delete(:class)
      @html_attrs = html_attrs
    end

    def call
      tag_name = @href ? :a : :li
      extra = @href ? { href: @href } : {}
      content_tag(tag_name,
        content.presence || @label,
        class: cn(BASE, VARIANTS.fetch(@variant, VARIANTS[:default]), @extra_class),
        **extra,
        **@html_attrs)
    end
  end
end
