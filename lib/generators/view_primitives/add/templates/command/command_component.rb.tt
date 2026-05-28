# frozen_string_literal: true

module UI
  class CommandComponent < ApplicationComponent
    renders_one :trigger

    OVERLAY = "fixed inset-0 z-50 bg-black/80"
    DIALOG  = "fixed left-[50%] top-[50%] z-50 w-full max-w-lg translate-x-[-50%] translate-y-[-50%] " \
              "overflow-hidden rounded-lg border bg-background shadow-lg"
    SEARCH  = "flex h-10 w-full items-center gap-2 border-b px-3"
    LIST    = "max-h-[300px] scroll-py-1 overflow-x-hidden overflow-y-auto"
    EMPTY   = "py-6 text-center text-sm text-muted-foreground"

    # Wrap each group of items in a div with this class.
    GROUP_WRAPPER = "overflow-hidden p-1 text-foreground"
    # Apply to the heading element (p/span) inside a group wrapper.
    GROUP         = "px-2 py-1.5 text-xs font-medium text-muted-foreground"
    # Apply to each actionable item button/link.
    ITEM          = "relative flex w-full cursor-default select-none items-center gap-2 rounded-sm " \
                    "px-2 py-1.5 text-sm outline-none " \
                    "hover:bg-accent hover:text-accent-foreground " \
                    "[&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 " \
                    "[&_svg:not([class*='text-'])]:text-muted-foreground"
    # Place inside an ITEM as the last child to show a keyboard shortcut on the right.
    SHORTCUT      = "ml-auto text-xs tracking-widest text-muted-foreground"
    # Horizontal rule between groups (use a plain <hr> tag).
    SEPARATOR     = "-mx-1 h-px bg-border"

    def initialize(**html_attrs)
      @extra_class = html_attrs.delete(:class)
      @html_attrs  = html_attrs
    end

    def call
      content_tag(:div, data: { controller: "command" }, **@html_attrs) do
        concat content_tag(:span, trigger, data: { action: "click->command#open" }, class: "contents") if trigger
        concat panel
      end
    end

    private

    def panel
      content_tag(:div, data: { command_target: "panel" }, hidden: true) do
        concat content_tag(:div, nil,
          class: OVERLAY,
          data: { action: "click->command#close" },
          "aria-hidden": "true")
        concat content_tag(:div,
          class: cn(DIALOG, @extra_class),
          role: "dialog",
          "aria-modal": "true",
          data: { action: "keydown.escape@window->command#close" }) {
          concat search_bar
          concat content_tag(:div, class: LIST, data: { command_target: "list" }) {
            concat content
          }
          concat content_tag(:div, "No results found.",
            class: EMPTY,
            data: { command_target: "empty" },
            hidden: true)
        }
      end
    end

    def search_bar
      content_tag(:div, class: SEARCH) do
        concat search_icon
        concat tag.input(
          type: "text",
          placeholder: "Type a command or search...",
          class: "flex-1 bg-transparent text-sm outline-none placeholder:text-muted-foreground",
          data: {
            command_target: "input",
            action: "input->command#filter"
          }
        )
      end
    end

    def search_icon
      raw('<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="shrink-0 text-muted-foreground" aria-hidden="true"><circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/></svg>')
    end
  end
end
