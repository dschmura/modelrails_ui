# frozen_string_literal: true

module UI
  class DataTableComponent < ApplicationComponent
    # Sortable, filterable data table with client-side pagination.
    #
    # columns: array of { key:, label:, sortable: true }
    # rows:    array of hashes (keys must match column keys)
    # per_page: rows per page (default 10, 0 = no pagination)
    # caption:  optional <caption> text

    WRAPPER    = "w-full overflow-auto rounded-lg border border-border"
    TOOLBAR    = "flex items-center gap-3 border-b border-border bg-background px-4 py-3"
    SEARCH_CLS = "flex h-8 flex-1 items-center gap-2 rounded-md border border-input bg-background " \
                 "px-3 text-sm text-muted-foreground focus-within:border-ring focus-within:ring-[3px] " \
                 "focus-within:ring-ring/50 transition"
    SEARCH_INPUT = "w-full bg-transparent outline-none placeholder:text-muted-foreground text-foreground text-sm"
    TABLE_CLS  = "w-full caption-bottom text-sm"
    THEAD_CLS  = "bg-muted/40"
    TH_CLS     = "h-10 px-4 text-left align-middle font-medium text-muted-foreground whitespace-nowrap"
    TH_SORT    = "cursor-pointer select-none hover:text-foreground transition-colors"
    TR_CLS     = "border-t border-border transition-colors hover:bg-muted/30"
    TD_CLS     = "px-4 py-3 align-middle"
    FOOTER_CLS = "flex items-center justify-between border-t border-border bg-background px-4 py-3 " \
                 "text-sm text-muted-foreground"
    PAGE_BTN   = "inline-flex h-8 w-8 items-center justify-center rounded-md border border-border " \
                 "hover:bg-accent hover:text-accent-foreground disabled:pointer-events-none " \
                 "disabled:opacity-40 transition"
    SORT_ASC   = "▲"
    SORT_DESC  = "▼"

    def initialize(columns:, rows:, per_page: 10, caption: nil, **html_attrs)
      @columns   = columns
      @rows      = rows
      @per_page  = per_page.to_i
      @caption   = caption
      @extra_class = html_attrs.delete(:class)
      @html_attrs  = html_attrs
    end

    def call
      content_tag(:div,
        class: cn(WRAPPER, @extra_class),
        data: {
          controller: "data-table",
          data_table_per_page_value: @per_page,
          data_table_total_value: @rows.size
        },
        **@html_attrs) do
        concat toolbar
        concat table_element
        concat footer if @per_page > 0
      end
    end

    private

    def toolbar
      content_tag(:div, class: TOOLBAR) do
        concat search_box
      end
    end

    def search_box
      content_tag(:label, class: SEARCH_CLS) do
        concat search_icon
        concat tag.input(
          type: "search", class: SEARCH_INPUT,
          placeholder: "Search…",
          data: {
            data_table_target: "search",
            action: "input->data-table#filter"
          })
      end
    end

    def table_element
      content_tag(:table, class: TABLE_CLS) do
        concat content_tag(:caption, @caption, class: "mt-2 text-sm text-muted-foreground") if @caption
        concat thead
        concat tbody
      end
    end

    def thead
      content_tag(:thead, class: THEAD_CLS) do
        content_tag(:tr) do
          safe_join(@columns.map { |col| th_cell(col) })
        end
      end
    end

    def th_cell(col)
      key     = col[:key].to_s
      label   = col[:label] || key.humanize
      sortable = col.fetch(:sortable, false)

      content_tag(:th, class: cn(TH_CLS, sortable ? TH_SORT : nil),
        data: sortable ? {
          action: "click->data-table#sort",
          data_table_key_param: key
        } : {}) do
        content_tag(:span, class: "flex items-center gap-1") do
          concat label
          if sortable
            concat content_tag(:span, SORT_ASC,
              class: "text-xs opacity-0 data-[active=asc]:opacity-100",
              data: { data_table_target: "sortIndicator", data_table_sort_key: key, data_table_dir: "asc" })
            concat content_tag(:span, SORT_DESC,
              class: "text-xs opacity-0 data-[active=desc]:opacity-100",
              data: { data_table_target: "sortIndicator", data_table_sort_key: key, data_table_dir: "desc" })
          end
        end
      end
    end

    def tbody
      content_tag(:tbody, data: { data_table_target: "body" }) do
        safe_join(@rows.map { |row| tr_row(row) })
      end
    end

    def tr_row(row)
      content_tag(:tr, class: TR_CLS, data: { data_table_row: true }) do
        safe_join(@columns.map { |col| td_cell(row, col[:key].to_s) })
      end
    end

    def td_cell(row, key)
      content_tag(:td, row[key.to_sym] || row[key], class: TD_CLS)
    end

    def footer
      content_tag(:div, class: FOOTER_CLS) do
        concat content_tag(:span, "Page 1",
          data: { data_table_target: "pageLabel" })
        concat(content_tag(:div, class: "flex items-center gap-1") {
          concat page_btn("‹", "click->data-table#prevPage", "Previous page")
          concat page_btn("›", "click->data-table#nextPage", "Next page")
        })
      end
    end

    def page_btn(label, action, aria)
      content_tag(:button, label, type: "button",
        class: PAGE_BTN,
        "aria-label": aria,
        data: { action: action })
    end

    def search_icon
      content_tag(:svg,
        safe_join([
          content_tag(:circle, nil, cx: "11", cy: "11", r: "8"),
          content_tag(:path, nil, d: "m21 21-4.3-4.3")
        ]),
        xmlns: "http://www.w3.org/2000/svg", viewBox: "0 0 24 24",
        fill: "none", stroke: "currentColor", "stroke-width": "2",
        "stroke-linecap": "round", "stroke-linejoin": "round",
        class: "size-4 shrink-0", "aria-hidden": "true")
    end
  end
end
