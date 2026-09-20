# frozen_string_literal: true

require "system_test_helper"
load_component "timepicker", "timepicker_component.rb.tt"

# Arrow stepping is BEHAVIOUR: the markup already declares hour and minute as
# role=spinbutton and already wires keydown at the controller, so the render lane
# reports a complete contract while the keys do nothing. This is the lane that can
# tell those apart (#219).
BrowserHarness.scenario("timepicker/h24", controllers: %w[timepicker],
  modules: %w[overlays/top_layer]) do
  view = ActionController::Base.new.view_context
  UI::TimepickerComponent.new(id: "tp", name: "start_at", label: "Start", value: "09:30").render_in(view)
end

# Seeded at both ceilings so a single ArrowUp exercises the wrap on either field.
BrowserHarness.scenario("timepicker/ceiling", controllers: %w[timepicker],
  modules: %w[overlays/top_layer]) do
  view = ActionController::Base.new.view_context
  UI::TimepickerComponent.new(id: "tp", name: "start_at", label: "Start", value: "23:59").render_in(view)
end

BrowserHarness.scenario("timepicker/quarter_hour", controllers: %w[timepicker],
  modules: %w[overlays/top_layer]) do
  view = ActionController::Base.new.view_context
  UI::TimepickerComponent.new(id: "tp", name: "start_at", label: "Start", value: "09:30", step: 15).render_in(view)
end

class TimepickerSystemTest < BrowserTestCase
  def open_picker
    find("[data-timepicker-target=trigger]").click
  end

  def hour = find("[data-timepicker-target=hour]")
  def minute = find("[data-timepicker-target=minute]")

  # The attribute value itself, not a predicate, so a failure names what the DOM says.
  def aria_valuenow(target)
    page.evaluate_script(%{document.querySelector("[data-timepicker-target=#{target}]").getAttribute("aria-valuenow")})
  end

  def aria_valuetext(target)
    page.evaluate_script(%{document.querySelector("[data-timepicker-target=#{target}]").getAttribute("aria-valuetext")})
  end

  def hidden_value = page.evaluate_script(%{document.querySelector("[data-timepicker-target=hidden]").value})

  # --- The contract the role promises ---

  def test_arrow_up_steps_the_hour
    visit_scenario("timepicker/h24")
    open_picker
    hour.send_keys(:up)

    assert_equal "10", hour.value
    assert_no_stimulus_errors
  end

  def test_arrow_down_steps_the_hour
    visit_scenario("timepicker/h24")
    open_picker
    hour.send_keys(:down)

    assert_equal "08", hour.value
    assert_no_stimulus_errors
  end

  def test_arrow_up_steps_the_minute
    visit_scenario("timepicker/h24")
    open_picker
    minute.send_keys(:up)

    assert_equal "31", minute.value
    assert_no_stimulus_errors
  end

  def test_arrow_down_steps_the_minute
    visit_scenario("timepicker/h24")
    open_picker
    minute.send_keys(:down)

    assert_equal "29", minute.value
    assert_no_stimulus_errors
  end

  # --- Boundaries, so wrap-around is pinned rather than inherited by accident ---

  def test_the_hour_wraps_past_its_maximum
    visit_scenario("timepicker/ceiling")
    open_picker
    hour.send_keys(:up)

    assert_equal "00", hour.value
  end

  def test_the_minute_wraps_past_fifty_nine
    visit_scenario("timepicker/ceiling")
    open_picker
    minute.send_keys(:up)

    assert_equal "00", minute.value
  end

  # --- The keyboard path is the same path the steppers take ---

  def test_stepping_by_key_syncs_the_spinbutton_value_contract
    visit_scenario("timepicker/h24")
    open_picker
    hour.send_keys(:up)

    assert_equal "10", aria_valuenow("hour")
    assert_equal "10", aria_valuetext("hour")
  end

  def test_stepping_by_key_commits_to_the_hidden_field
    visit_scenario("timepicker/h24")
    open_picker
    minute.send_keys(:up)

    assert_equal "09:31", hidden_value
  end

  # step: is the minute stepper's increment; the key path must honour it rather than
  # hard-coding 1, which is what routing both through the existing methods buys.
  def test_the_minute_key_step_honours_the_step_value
    visit_scenario("timepicker/quarter_hour")
    open_picker
    minute.send_keys(:up)

    assert_equal "45", minute.value
  end
end
