# frozen_string_literal: true

module UI
  class ButtonGroupComponent < ApplicationComponent
    BASE = "inline-flex rounded-md shadow-sm " \
           "[&>*]:rounded-none " \
           "[&>*:first-child]:rounded-l-md " \
           "[&>*:last-child]:rounded-r-md " \
           "[&>*:not(:first-child)]:-ml-px"

    def initialize(**html_attrs)
      @extra_class = html_attrs.delete(:class)
      @html_attrs = html_attrs
    end

    def call
      content_tag(:div, content,
        class: cn(BASE, @extra_class),
        role: "group",
        **@html_attrs)
    end
  end
end
