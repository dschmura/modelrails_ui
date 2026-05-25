# frozen_string_literal: true

module UI
  class ListGroupComponent < ApplicationComponent
    BASE = "divide-y divide-border overflow-hidden rounded-lg border"

    def initialize(**html_attrs)
      @extra_class = html_attrs.delete(:class)
      @html_attrs = html_attrs
    end

    def call
      content_tag(:ul, content, class: cn(BASE, @extra_class), **@html_attrs)
    end
  end
end
