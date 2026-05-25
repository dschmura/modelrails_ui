# frozen_string_literal: true

module UI
  class CardComponent < ApplicationComponent
    BASE = "bg-card text-card-foreground flex flex-col gap-6 rounded-xl border py-6 shadow-sm"

    def initialize(**html_attrs)
      @extra_class = html_attrs.delete(:class)
      @html_attrs = html_attrs
    end

    def call
      content_tag(:div, content, class: cn(BASE, @extra_class), **@html_attrs)
    end
  end
end
