# frozen_string_literal: true

require "render_test_helper"
load_component "calendar", "calendar_component.rb.tt"

# STRUCTURE-only render tests. The `calendar` Stimulus controller's behavior
# (prev/next paging, roving-tabindex arrow-key navigation, aria-selected /
# aria-current sync on month rebuild) is verified by an app-level 0b browser
# spec — the render harness CANNOT exercise JS. Here we assert the static
# APG date-grid scaffolding the controller relies on, plus the focus/label
# contract, never the runtime behavior itself.
class CalendarRenderTest < ViewComponent::TestCase
  include ActiveSupport::Testing::TimeHelpers

  # A fixed month so the grid layout is deterministic. June 2026 begins on a
  # Monday; the 15th is a Monday in the second visible week.
  JUNE = Date.new(2026, 6, 15)

  def render_default(**opts)
    render_inline(UI::CalendarComponent.new(month: JUNE, **opts))
  end

  # --- The month is a named grid (APG date-grid) -----------------------------

  # The whole month is one `role="grid"` whose accessible name is the month/year
  # caption — a screen reader announces "June 2026 grid" on entry.
  def test_month_is_a_grid_named_by_the_month_and_year
    render_default

    assert_selector "div[role='grid'][aria-label='June 2026'][data-calendar-target='grid']"
  end

  # The weekday header is a row of columnheaders (not bare divs), each with a
  # full-day-name expansion via <abbr title>.
  def test_weekday_header_is_a_row_of_columnheaders
    render_default

    assert_selector "[role='grid'] [role='row'] [role='columnheader']", count: 7
    assert_selector "[role='columnheader'] abbr[title='Sunday']", text: "Su"
    assert_selector "[role='columnheader'] abbr[title='Saturday']", text: "Sa"
  end

  # 6 week rows of 7 gridcells each = a full 42-cell month grid; every gridcell
  # wraps a real day <button>.
  def test_grid_has_six_week_rows_of_seven_day_gridcells
    render_default

    # 1 weekday header row + 6 week rows.
    assert_selector "[role='grid'] [role='row']", count: 7
    assert_selector "[role='gridcell']", count: 42
    assert_selector "[role='gridcell'] button[type='button']", count: 42
  end

  # --- Today + selected must keep on-color text ------------------------------

  # Regression: when the selected day IS today, the today indicator must not
  # override the selected fill's on-color text. The today cell carried
  # `text-text-heading`, which won the cascade over DAY_SEL's
  # `text-text-on-interactive` and put heading text on the bg-interactive fill —
  # a dark-mode contrast failure the app's preview-host axe spec caught.
  def test_today_when_also_selected_keeps_on_interactive_text
    travel_to(JUNE) do # JUNE is today, so today == the selected day
      render_inline(UI::CalendarComponent.new(month: JUNE, selected: JUNE))
    end

    today = page.find("button[aria-current='date']")

    assert_includes today[:class], "bg-interactive"
    assert_includes today[:class], "text-text-on-interactive"
    refute_includes today[:class], "text-text-heading"
  end

  # --- Day buttons carry a full-date accessible name -------------------------

  # The bare day number is not enough out of column/row context — each day
  # button's accessible name is the full date.
  def test_day_buttons_have_full_date_aria_labels
    render_default

    assert_selector "button[aria-label='15 June 2026']", text: "15"
    assert_selector "button[aria-label='1 June 2026']", text: "1"
  end

  # --- Selected / today state -------------------------------------------------

  def test_selected_day_is_marked_on_the_cell_and_the_button
    render_default(selected: JUNE)

    assert_selector "[role='gridcell'][aria-selected='true'] button[aria-pressed='true']", text: "15"
    # Sibling cells are not selected.
    assert_selector "[role='gridcell'][aria-selected='false']", minimum: 1
  end

  def test_today_carries_aria_current_date
    travel_month = Date.today
    render_inline(UI::CalendarComponent.new(month: travel_month))

    assert_selector "button[aria-current='date']", text: travel_month.day.to_s
  end

  # No selection + a month that is not the current month ⇒ no aria-current/aria-selected.
  def test_no_selection_no_today_means_no_marked_day
    render_default # June 2026, no selected:

    assert_no_selector "button[aria-pressed='true']"
    assert_no_selector "[role='gridcell'][aria-selected='true']"
  end

  # --- Roving tabindex (exactly one tabbable day) ----------------------------

  # APG: exactly one day button is in the tab order; the rest are reached with
  # the keyboard. With a selection, the selected day is the tabbable one.
  def test_exactly_one_day_is_tabbable_and_it_is_the_selected_day
    render_default(selected: JUNE)

    assert_selector "button[data-calendar-date-param][tabindex='0']", count: 1
    assert_selector "button[tabindex='0'][aria-label='15 June 2026']"
    assert_selector "button[data-calendar-date-param][tabindex='-1']", count: 41
  end

  # Without a selection (and a month that does not contain today) the first of
  # the month is the single tabbable cell.
  def test_first_of_month_is_tabbable_when_nothing_is_selected
    # A month far from "today" so today isn't shown and can't claim the roving slot.
    render_inline(UI::CalendarComponent.new(month: Date.new(2030, 3, 10)))

    assert_selector "button[data-calendar-date-param][tabindex='0']", count: 1
    assert_selector "button[tabindex='0'][aria-label='1 March 2030']"
  end

  # Day buttons wire both selection and keyboard navigation actions.
  def test_day_buttons_wire_select_and_navigate_actions
    render_default

    assert_selector "button[data-action~='click->calendar#selectDay']", minimum: 1
    assert_selector "button[data-action~='keydown->calendar#navigate']", minimum: 1
  end

  # --- Prev/next month controls ----------------------------------------------

  # Prev/next are real i18n-labelled buttons (not icon-only-unlabelled) carrying
  # the AAA offset focus-ring and a 44px target.
  def test_prev_next_are_i18n_labelled_focus_ring_buttons
    render_default

    assert_selector "button.focus-ring[aria-label='Previous month'][data-action~='click->calendar#prevMonth']"
    assert_selector "button.focus-ring[aria-label='Next month'][data-action~='click->calendar#nextMonth']"
    # 44px AAA target floor.
    assert_selector "button.size-11[aria-label='Previous month']"
  end

  # The chevron SVG is decorative — hidden from the a11y tree so the button's
  # aria-label is the sole accessible name.
  def test_chevron_is_decorative
    render_default

    assert_selector "button[aria-label='Previous month'] svg[aria-hidden='true']"
  end

  # --- Focus-ring contract ----------------------------------------------------

  # Day buttons carry the offset focus-ring (not a box-shadow ring).
  def test_day_buttons_carry_the_focus_ring
    render_default

    assert_selector "[role='gridcell'] button.focus-ring", minimum: 42
  end

  # Regression guard: the box-shadow ring / outline-none anti-pattern must never
  # come back (it's clipped by overflow:hidden and vanishes in forced-colors).
  def test_no_box_shadow_ring_or_outline_none
    render_default
    html = page.native.to_html

    refute_includes html, "focus-visible:ring-"
    refute_includes html, "outline-none"
  end

  # --- weekday_start enum -----------------------------------------------------

  def test_monday_start_reorders_the_columns
    render_default(weekday_start: :monday)

    headers = page.all("[role='columnheader'] abbr").map(&:text)

    assert_equal "Mo", headers.first
    assert_equal "Su", headers.last
  end

  # Fail loud: an unknown weekday_start would silently mis-order columns.
  def test_unknown_weekday_start_raises
    assert_raises(ArgumentError) do
      render_inline(UI::CalendarComponent.new(weekday_start: :wednesday))
    end
  end

  # --- Form integration -------------------------------------------------------

  def test_renders_a_hidden_input_when_named_and_selected
    render_default(name: "event[date]", selected: JUNE)

    assert_selector "input[type='hidden'][name='event[date]'][value='2026-06-15']", visible: :all
  end

  # --- html_attrs passthrough -------------------------------------------------

  # html_attrs pass through onto the root AND the calendar controller wiring is
  # preserved (a caller-supplied data: must not clobber data-controller).
  def test_passes_through_html_attrs_and_preserves_the_controller
    render_inline(UI::CalendarComponent.new(month: JUNE, id: "due-date", data: {testid: "cal"}))

    assert_selector "div#due-date[data-controller='calendar'][data-testid='cal']"
    assert_selector "div[data-calendar-month-value='2026-06-01']"
  end

  # A caller-supplied class merges onto the root without clobbering the container tokens.
  def test_merges_caller_class_onto_the_root
    render_default(class: "mt-4")

    assert_selector "div.mt-4.bg-surface-overlay"
  end
end
