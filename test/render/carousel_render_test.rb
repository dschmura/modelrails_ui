# frozen_string_literal: true

require "render_test_helper"
load_component "carousel", "carousel_component.rb.tt"

class CarouselRenderTest < ViewComponent::TestCase
  def carousel(**opts)
    render_inline(UI::CarouselComponent.new(**opts)) do |c|
      c.with_slide { "one" }
      c.with_slide { "two" }
      c.with_slide { "three" }
    end
  end

  def test_root_is_a_carousel_group
    carousel

    assert_selector "div[role='group'][aria-roledescription='carousel'][aria-label]"
  end

  def test_each_slide_is_a_labelled_slide_group
    carousel

    assert_selector "[role='group'][aria-roledescription='slide']", count: 3
    assert_selector "[aria-roledescription='slide'][aria-label='1 of 3']"
    assert_selector "[aria-roledescription='slide'][aria-label='3 of 3']"
  end

  def test_prev_next_are_44px_and_use_focus_ring_not_a_ring
    carousel

    assert_selector "button.size-11.focus-ring[aria-label]", minimum: 2
    assert_no_selector "[class*='focus-visible:ring']"
  end

  def test_dots_carry_a_44px_target_and_aria_current
    carousel

    assert_selector "[data-carousel-target='dots'] button.size-11[aria-current]", count: 3
    assert_selector "[data-carousel-target='dots'] button[aria-current='true']", count: 1
  end

  def test_pause_button_present_only_when_autoplay_set
    carousel(autoplay: 4000)

    assert_selector "button[data-carousel-target='pause'][aria-label]"
  end

  def test_no_pause_button_without_autoplay
    carousel

    assert_no_selector "[data-carousel-target='pause']"
  end

  def test_live_region_starts_off
    carousel

    assert_selector "[data-carousel-target='status'][aria-live='off']", visible: :all
  end

  def test_root_wires_hover_focus_suspend_resume
    carousel(autoplay: 4000)

    assert_selector "div[data-action~='mouseenter->carousel#suspend'][data-action~='focusout->carousel#resume']"
  end
end
