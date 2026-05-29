# frozen_string_literal: true

module UI
  class CalendarComponent < ApplicationComponent
    # Month-grid calendar. Renders a full month; selected/today dates are highlighted.
    #
    # selected:   Date or nil — highlighted day
    # month:      Date — controls which month is shown (defaults to today)
    # name:       form field name for the hidden input (if used in a form)
    # min/max:    Date bounds for disabled days

    CONTAINER  = "w-fit rounded-lg border border-border bg-popover p-4 text-sm shadow"
    HEADER_CLS = "mb-3 flex items-center justify-between"
    MONTH_CLS  = "font-medium text-foreground"
    NAV_BTN    = "inline-flex size-7 items-center justify-center rounded-md " \
                 "text-muted-foreground hover:bg-accent hover:text-accent-foreground " \
                 "focus-visible:ring-[3px] focus-visible:ring-ring/50 outline-none transition"
    GRID_CLS   = "grid grid-cols-7 gap-px"
    DOW_CLS    = "py-1.5 text-center text-xs text-muted-foreground font-medium"
    DAY_BASE   = "h-9 w-9 rounded-md text-center text-sm transition-colors outline-none " \
                 "focus-visible:ring-[3px] focus-visible:ring-ring/50"
    DAY_NORMAL = "hover:bg-accent hover:text-accent-foreground"
    DAY_TODAY  = "font-semibold text-foreground ring-1 ring-border"
    DAY_SEL    = "bg-primary text-primary-foreground hover:bg-primary/90"
    DAY_MUTED  = "text-muted-foreground/50"
    DAY_DISABLED = "pointer-events-none opacity-30"

    DAYS_OF_WEEK = %w[Su Mo Tu We Th Fr Sa].freeze
    CHEVRON_L    = "m15 18-6-6 6-6"
    CHEVRON_R    = "m9 18 6-6-6-6"

    def initialize(selected: nil, month: nil, name: nil, min: nil, max: nil, **html_attrs)
      @selected = selected
      @month    = (month || Date.today).beginning_of_month
      @name     = name
      @min      = min
      @max      = max
      @extra_class = html_attrs.delete(:class)
      @html_attrs  = html_attrs
    end

    def call
      content_tag(:div,
        class: cn(CONTAINER, @extra_class),
        data: { controller: "calendar", calendar_month_value: @month.iso8601 },
        **@html_attrs) do
        concat hidden_input if @name && @selected
        concat header_row
        concat day_of_week_row
        concat day_grid
      end
    end

    private

    def hidden_input
      tag.input(type: "hidden", name: @name, value: @selected&.iso8601)
    end

    def header_row
      content_tag(:div, class: HEADER_CLS) do
        concat nav_btn(CHEVRON_L, "Previous month", "click->calendar#prevMonth")
        concat content_tag(:span, @month.strftime("%B %Y"), class: MONTH_CLS,
          data: { calendar_target: "monthLabel" })
        concat nav_btn(CHEVRON_R, "Next month", "click->calendar#nextMonth")
      end
    end

    def nav_btn(path, label, action)
      content_tag(:button, type: "button", class: NAV_BTN,
        "aria-label": label, data: { action: action }) { chevron(path) }
    end

    def day_of_week_row
      content_tag(:div, class: GRID_CLS) do
        safe_join(DAYS_OF_WEEK.map { |d| content_tag(:div, d, class: DOW_CLS) })
      end
    end

    def day_grid
      today = Date.today
      first = @month.beginning_of_month
      start = first - first.wday
      days  = (start..(start + 41)).to_a

      content_tag(:div, class: GRID_CLS, data: { calendar_target: "grid" }) do
        safe_join(days.map { |d| day_cell(d, today, first) })
      end
    end

    def day_cell(date, today, first)
      outside  = date.month != first.month
      selected = @selected && date == @selected
      is_today = date == today
      disabled = (@min && date < @min) || (@max && date > @max)

      classes = cn(DAY_BASE,
        selected  ? DAY_SEL    : DAY_NORMAL,
        is_today  ? DAY_TODAY  : nil,
        outside   ? DAY_MUTED  : nil,
        disabled  ? DAY_DISABLED : nil)

      content_tag(:button,
        date.day.to_s,
        type: "button",
        class: classes,
        "aria-label": date.strftime("%B %-d, %Y"),
        "aria-pressed": selected.to_s,
        disabled: disabled || nil,
        data: { action: "click->calendar#selectDay", calendar_date_param: date.iso8601 })
    end

    def chevron(path)
      content_tag(:svg,
        content_tag(:path, nil, d: path, "stroke-linecap": "round", "stroke-linejoin": "round"),
        xmlns: "http://www.w3.org/2000/svg", viewBox: "0 0 24 24",
        fill: "none", stroke: "currentColor", "stroke-width": "2",
        class: "size-4", "aria-hidden": "true")
    end
  end
end
