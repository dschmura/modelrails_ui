# frozen_string_literal: true

module UI
  class TextareaComponent < ApplicationComponent
    BASE = "flex field-sizing-content min-h-16 w-full rounded-md border border-input bg-transparent px-3 py-2 " \
           "text-base shadow-xs transition-[color,box-shadow] outline-none " \
           "placeholder:text-muted-foreground " \
           "focus-visible:border-ring focus-visible:ring-[3px] focus-visible:ring-ring/50 " \
           "aria-invalid:border-destructive aria-invalid:ring-destructive/20 dark:aria-invalid:ring-destructive/40 " \
           "disabled:cursor-not-allowed disabled:opacity-50 " \
           "md:text-sm dark:bg-input/30 dark:aria-invalid:ring-destructive/40"

    def initialize(**html_attrs)
      @extra_class = html_attrs.delete(:class)
      @html_attrs = html_attrs
    end

    def call
      content_tag(:textarea, content,
        class: cn(BASE, @extra_class),
        **@html_attrs)
    end
  end
end
