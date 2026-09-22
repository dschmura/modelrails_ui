# frozen_string_literal: true

require "render_test_helper"
load_component "chip_group", "chip_group_component.rb.tt"

class ChipGroupRenderTest < ViewComponent::TestCase
  DAYS = [
    {value: "mon", label: "Mon", aria_label: "Monday"},
    {value: "tue", label: "Tue", aria_label: "Tuesday", checked: true}
  ].freeze

  def render_days(**opts)
    render_inline(UI::ChipGroupComponent.new(
      name: "prefs[days]", label: "Active days", items: DAYS, **opts
    ))
  end

  # --- form participation is the whole point -------------------------------

  def test_each_chip_is_a_real_checkbox
    render_days

    assert_selector "input[type='checkbox'][value='mon']", visible: :all
    assert_selector "input[type='checkbox'][value='tue']", visible: :all
  end

  # Multi-select posts as an array. Forgetting the [] is the classic way this
  # silently submits only the last value, so the component appends it.
  def test_the_name_is_an_array_name
    render_days

    assert_selector "input[type='checkbox'][name='prefs[days][]']", visible: :all
  end

  def test_a_name_that_already_ends_in_brackets_is_not_doubled
    render_days(name: "prefs[days][]")

    assert_selector "input[type='checkbox'][name='prefs[days][]']", visible: :all
    assert_no_selector "input[name='prefs[days][][]']", visible: :all
  end

  def test_checked_items_are_checked
    render_days

    assert_selector "input[value='tue'][checked]", visible: :all
    assert_no_selector "input[value='mon'][checked]", visible: :all
  end

  # Unchecking everything must still submit the key, or the server reads
  # "no change" where the user meant "none".
  def test_an_empty_sentinel_keeps_the_key_present_when_nothing_is_checked
    render_days

    assert_selector "input[type='hidden'][name='prefs[days][]'][value='']", visible: :all
  end

  def test_the_sentinel_can_be_opted_out_of
    render_days(include_hidden: false)

    assert_no_selector "input[type='hidden']", visible: :all
  end

  # --- the chip is the target ----------------------------------------------

  # sr-only rather than hidden: a hidden input is not focusable, so the group
  # would be unreachable by keyboard.
  def test_the_checkbox_is_visually_hidden_but_still_a_real_focusable_control
    render_days

    assert_selector "input[type='checkbox'].sr-only", visible: :all
    assert_no_selector "input[type='checkbox'][hidden]", visible: :all
  end

  def test_the_whole_chip_is_the_label_for_its_input
    render_days

    assert_selector "label[for='prefs_days_mon'] input#prefs_days_mon", visible: :all
  end

  def test_the_chip_meets_the_44px_target_floor
    render_days

    assert_selector "label.min-h-input.min-w-11"
  end

  # Focus is an offset outline, never a ring: a ring is clipped by an
  # overflow:hidden ancestor and vanishes in forced-colors mode (2.4.7).
  def test_focus_is_an_outline_and_never_a_ring
    render_days

    assert_selector "label[class*='has-[:focus-visible]:outline-2']"
    assert_no_selector "label[class*='ring']"
  end

  # bg-surface is the PAGE; a bordered container is bg-surface-raised.
  def test_the_chip_sits_on_the_raised_surface_not_the_page
    render_days

    assert_selector "label.bg-surface-raised"
  end

  # --- naming ---------------------------------------------------------------

  def test_an_abbreviated_chip_announces_its_full_name
    render_days

    assert_selector "span[aria-label='Monday']", text: "Mon"
  end

  # No aria_label means the visible text IS the name — an empty aria-label would
  # strip the accessible name entirely.
  def test_a_chip_without_an_aria_label_emits_none
    render_inline(UI::ChipGroupComponent.new(
      name: "prefs[tags]", label: "Tags", items: [{value: "ruby", label: "Ruby"}]
    ))

    assert_no_selector "span[aria-label]"
    assert_selector "span", text: "Ruby"
  end

  # --- group contract -------------------------------------------------------

  def test_the_group_is_a_named_group
    render_days

    assert_selector "div[role='group'][aria-label='Active days']"
  end

  def test_invalid_sets_aria_invalid_on_the_group
    render_days(invalid: true)

    assert_selector "div[role='group'][aria-invalid='true']"
  end

  def test_describedby_links_the_group_to_a_hint_or_error
    render_days(describedby: "days-error")

    assert_selector "div[role='group'][aria-describedby='days-error']"
  end

  def test_a_caller_cannot_clobber_the_groups_a11y_contract
    render_days(:role => "list", "aria-label" => "Hijacked")

    assert_selector "div[role='group'][aria-label='Active days']"
    assert_no_selector "div[role='list']"
  end

  def test_a_disabled_chip_is_honoured
    render_inline(UI::ChipGroupComponent.new(
      name: "prefs[days]", label: "Active days",
      items: [{value: "sun", label: "Sun", disabled: true}]
    ))

    assert_selector "input[value='sun'][disabled]", visible: :all
  end
end
