# frozen_string_literal: true

module UI
  class MenubarComponent < ApplicationComponent
    renders_many :menus, "UI::MenubarMenuComponent"

    BAR  = "flex h-9 items-center gap-1 rounded-md border bg-background p-1 shadow-xs"
    ITEM = "relative flex cursor-default select-none items-center gap-2 rounded-sm " \
           "px-2 py-1.5 text-sm outline-none " \
           "hover:bg-accent hover:text-accent-foreground " \
           "[&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 " \
           "[&_svg:not([class*='text-'])]:text-muted-foreground"
    SEPARATOR = "-mx-1 my-1 h-px bg-border"
    LABEL_CLS = "px-2 py-1.5 text-sm font-medium"

    def initialize(**html_attrs)
      @extra_class = html_attrs.delete(:class)
      @html_attrs  = html_attrs
    end

    def call
      content_tag(:div,
        class: cn(BAR, @extra_class),
        data: {
          controller: "menubar",
          action: "click@document->menubar#closeOnClickOutside keydown.escape@document->menubar#closeAll"
        },
        **@html_attrs) do
        menus.each { |m| concat m }
      end
    end
  end
end
