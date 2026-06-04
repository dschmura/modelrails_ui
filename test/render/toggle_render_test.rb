# frozen_string_literal: true

require "render_test_helper"
load_component "toggle", "toggle_component.rb.tt"

class ToggleRenderTest < ViewComponent::TestCase
  def test_default_renders_unpressed_toggle_button
    render_inline(UI::ToggleComponent.new("Bold"))

    assert_selector "button[type='button'][aria-pressed='false'][data-state='off']", text: "Bold"
  end

  def test_pressed_renders_pressed_state
    render_inline(UI::ToggleComponent.new("Bold", pressed: true))

    assert_selector "button[type='button'][aria-pressed='true'][data-state='on']", text: "Bold"
  end

  def test_keeps_toggle_stimulus_wiring
    render_inline(UI::ToggleComponent.new("Bold"))

    assert_selector "button[data-controller='toggle'][data-action='click->toggle#toggle']"
  end

  # AAA 2.5.5 target-size: every size must render a >=44px tall control.
  # h-11 = 44px (default/sm), h-12 = 48px (lg). Sub-44px heights are an AAA fail.
  def test_default_size_meets_44px_floor
    render_inline(UI::ToggleComponent.new("Bold"))

    assert_selector "button.h-11"
  end

  def test_sm_size_meets_44px_floor
    render_inline(UI::ToggleComponent.new("Bold", size: :sm))

    assert_selector "button.h-11"
  end

  def test_lg_size_meets_44px_floor
    render_inline(UI::ToggleComponent.new("Bold", size: :lg))

    assert_selector "button.h-12"
  end

  # Fail-loud size guard: an unknown size raises in development/test.
  def test_unknown_size_raises
    assert_raises(ArgumentError) do
      render_inline(UI::ToggleComponent.new("Bold", size: :bogus))
    end
  end

  # AAA semantic tokens (the design-token guarantee), not raw Tailwind. Selected
  # (on) uses the tinted interactive-subtle surface — DISTINCT from the neutral
  # off-hover surface — so clicking to select gives immediate visible feedback.
  def test_selected_state_is_a_distinct_tinted_surface
    render_inline(UI::ToggleComponent.new("Bold", pressed: true))

    assert_selector "button.data-\\[state\\=on\\]\\:bg-interactive-subtle"
    assert_selector "button.data-\\[state\\=on\\]\\:text-interactive"
  end

  # Hover is scoped to the OFF state so a selected toggle keeps its tinted look on
  # hover. Regression guard: the prior unscoped `hover:bg-surface-sunken` made the
  # hover surface identical to the selected surface (hover looked like selected).
  def test_hover_is_scoped_to_the_off_state
    render_inline(UI::ToggleComponent.new("Bold"))

    assert_selector "button.data-\\[state\\=off\\]\\:hover\\:bg-surface-sunken"
    refute_selector "button.hover\\:bg-surface-sunken"
  end
end
