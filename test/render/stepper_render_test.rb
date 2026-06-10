# frozen_string_literal: true

require "render_test_helper"
load_component "stepper", "stepper_component.rb.tt"

# STRUCTURE-only render specs. Stepper is a non-interactive progress indicator:
# an <ol aria-label="Progress"> whose steps carry their status via aria. Here we
# assert the scaffolding + the i18n/status/orientation contract; the app 0b proves
# it axe-AAA in a real browser.
class StepperRenderTest < ViewComponent::TestCase
  THREE_STEPS = [
    {label: "Account", status: :complete},
    {label: "Profile", status: :current},
    {label: "Confirm", status: :pending}
  ].freeze

  def test_renders_an_ordered_list_with_the_i18n_progress_label
    render_inline(UI::StepperComponent.new(steps: THREE_STEPS))

    # The aria-label resolves to the English default ("Progress") via I18n.t.
    assert_selector "ol[aria-label='Progress']"
  end

  def test_complete_step_renders_the_check_svg_and_the_completed_label
    render_inline(UI::StepperComponent.new(steps: THREE_STEPS))

    # The completed circle is named for AT and the check glyph is decorative.
    assert_selector "span[aria-label='Completed'] svg[aria-hidden='true']"
  end

  def test_current_step_carries_aria_current_step
    render_inline(UI::StepperComponent.new(steps: THREE_STEPS))

    assert_selector "span[aria-current='step']"
  end

  def test_pending_step_carries_the_i18n_pending_label
    render_inline(UI::StepperComponent.new(steps: THREE_STEPS))

    assert_selector "span[aria-label='Pending']"
  end

  def test_status_defaults_to_pending_when_omitted
    render_inline(UI::StepperComponent.new(steps: [{label: "Lonely"}]))

    assert_selector "span[aria-label='Pending']"
  end

  def test_horizontal_orientation_lays_steps_out_in_a_row
    render_inline(UI::StepperComponent.new(steps: THREE_STEPS, orientation: :horizontal))

    assert_selector "ol.flex.items-start"
    # Non-last horizontal items stretch to fill the row.
    assert_selector "li.flex.items-center.flex-1"
  end

  def test_vertical_orientation_stacks_steps_in_a_column
    render_inline(UI::StepperComponent.new(steps: THREE_STEPS, orientation: :vertical))

    assert_selector "ol.flex.flex-col"
    assert_selector "li.relative.flex.gap-4"
  end

  def test_unknown_orientation_raises
    assert_raises(ArgumentError) do
      render_inline(UI::StepperComponent.new(steps: THREE_STEPS, orientation: :diagonal))
    end
  end

  def test_unknown_step_status_raises
    assert_raises(ArgumentError) do
      render_inline(UI::StepperComponent.new(steps: [{label: "Bad", status: :bogus}]))
    end
  end

  # html_attrs pass through onto the root <ol>, matching the sibling components.
  def test_passes_through_html_attrs_onto_the_root
    render_inline(UI::StepperComponent.new(steps: THREE_STEPS, id: "checkout-steps", data: {testid: "stepper"}))

    assert_selector "ol#checkout-steps[data-testid='stepper'][aria-label='Progress']"
  end

  # A caller-supplied class merges onto the root without clobbering the layout tokens.
  def test_merges_caller_class_onto_the_root
    render_inline(UI::StepperComponent.new(steps: THREE_STEPS, class: "mt-4"))

    assert_selector "ol.mt-4.flex.items-start"
  end
end
