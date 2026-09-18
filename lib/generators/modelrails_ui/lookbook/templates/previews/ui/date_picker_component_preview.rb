# frozen_string_literal: true

module UI
  # # Date Picker
  #
  # A typeable date field with an inline calendar popover beside it, driven by the
  # `date-picker` Stimulus controller. The TEXT INPUT is the primary control — a date
  # you already know can be typed rather than found in the grid — and the icon button
  # opens the calendar as a secondary affordance. Escape or an outside click closes
  # the popover and returns focus to the trigger. The grid itself is owned by
  # `UI::CalendarComponent`.
  #
  # Typing commits on blur or Enter, is bound-checked against `min:`/`max:`, and is
  # written back in the display format. A rejected value announces why and leaves the
  # stored value untouched.
  #
  # ## Accessibility contract
  # - **Guarantees:** the caption is a real `<label for>` bound to the text input (a
  #   `<label for>` may only name a labelable element); a typeable path to any date, so
  #   the month grid is never the only way in; a real `<button>` trigger with
  #   `aria-haspopup="dialog"`, `aria-expanded` (kept in sync) and `aria-controls` → the
  #   popover, named for what it does since the caption names the field; the popover is
  #   a `role="dialog"` named by `label:`; the format hint and an error region are wired
  #   via `aria-describedby`, the region present and empty from first render; a rejected
  #   value sets `aria-invalid="true"`; the decorative calendar icon is `aria-hidden`.
  # - **You supply:** an optional `label:` (caption + popover name), `name:` (to post
  #   back), and `format:` (the display + hint pattern).
  #
  # ## Related
  # `calendar` · `timepicker`
  # @logical_path Forms & Inputs
  class DatePickerComponentPreview < ViewComponent::Preview
    include UIHelper

    # @!group Examples

    # Standard picker: a labelled text input you can type into, the calendar button
    # beside it, and a format hint. No initial value, so the box shows its placeholder.
    def default
    end

    # Two pickers as a range — the composition this component supports instead of a
    # range mode. Each carries its own caption, so the two fields and their two
    # dialogs are distinguishable by name.
    # @label Range · two pickers
    def range_pair
    end

    # Bounds are enforced on TYPED values as well as in the grid: type 2020-01-01
    # here and it is refused with a reason, rather than quietly accepted because it
    # did not come from the calendar.
    # @label Bounds · typed and picked
    def bounded
    end

    # @!endgroup

    # @!group Reference

    # Edit `label`, `format`, and `name` live. `format:` drives how a value is DISPLAYED
    # in the text input and the human-readable hint (`:long` → MMMM D, YYYY, `:short` → M/D/YYYY,
    # `:iso` → YYYY-MM-DD); an unknown key fails loud.
    # @param label text
    # @param format select [long, short, iso]
    # @param name text
    def playground(label: "Choose date", format: :long, name: "event[date]")
      ui :date_picker, label: label, format: format.to_sym, name: name
    end

    # @!endgroup
  end
end
