# frozen_string_literal: true

module UI
  class AvatarComponent < ApplicationComponent
    SIZES = { sm: "size-6", default: "size-8", lg: "size-12" }.freeze
    BASE = "relative flex shrink-0 overflow-hidden rounded-full select-none"
    IMAGE = "aspect-square size-full object-cover"
    FALLBACK = "flex size-full items-center justify-center rounded-full bg-muted text-sm text-muted-foreground"

    def initialize(src: nil, alt: "", fallback: nil, size: :default, **html_attrs)
      @src = src
      @alt = alt
      @fallback = fallback
      @size = size.to_sym
      @extra_class = html_attrs.delete(:class)
      @html_attrs = html_attrs
    end

    def call
      content_tag(:div, class: cn(BASE, SIZES[@size], @extra_class), **@html_attrs) do
        if @src
          content_tag(:img, nil, src: @src, alt: @alt, class: IMAGE)
        else
          content_tag(:span, initials(@fallback || @alt), class: FALLBACK)
        end
      end
    end

    private

    def initials(text)
      return "" if text.nil? || text.strip.empty?

      text.split.first(2).map { |word| word[0] }.join.upcase
    end
  end
end
