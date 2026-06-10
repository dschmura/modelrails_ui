# frozen_string_literal: true

require "render_test_helper"
load_component "resizable", "resizable_component.rb.tt"

# STRUCTURE-only render specs. The resize handle is the APG window-splitter: a
# focusable role="separator" the user can grab with the mouse OR drive with the
# keyboard. Here we assert the splitter scaffolding + the 2.1.1/focus contract;
# the app 0b proves AAA contrast and real keyboard resize in a browser.
class ResizableRenderTest < ViewComponent::TestCase
  def render_basic(**opts)
    render_inline(UI::ResizableComponent.new(**opts)) do |r|
      r.with_panel(min: 20, max: 80, default: 30) { "left" }
      r.with_panel { "right" }
    end
  end

  # WCAG 2.1.1: the handle is a focusable, named separator carrying the splitter
  # value range, so a keyboard-only user can focus it and arrow-resize.
  def test_handle_is_a_focusable_named_separator
    render_basic

    assert_selector "div[tabindex='0'][role='separator'][aria-label='Resize panels']"
  end

  # The splitter exposes its range — valuenow mirrors the leading panel's default,
  # valuemin/valuemax mirror its min/max.
  def test_handle_exposes_the_splitter_value_range
    render_basic

    assert_selector "div[role='separator'][aria-valuenow='30'][aria-valuemin='20'][aria-valuemax='80']"
  end

  # A horizontal split lays panels side-by-side, so the separator bar is vertical.
  def test_horizontal_direction_orients_the_separator_vertically
    render_basic(direction: :horizontal)

    assert_selector "div.flex-row"
    assert_selector "div[role='separator'][aria-orientation='vertical']"
  end

  # A vertical split stacks panels, so the separator bar is horizontal.
  def test_vertical_direction_orients_the_separator_horizontally
    render_basic(direction: :vertical)

    assert_selector "div.flex-col"
    assert_selector "div[role='separator'][aria-orientation='horizontal']"
  end

  # The handle needs a visible focus indicator: the offset focus-ring utility.
  def test_handle_carries_the_focus_ring
    render_basic

    assert_selector "div.focus-ring[role='separator']"
  end

  # The keyboard path is wired: arrow/Home/End resize routes through onKeydown.
  def test_handle_wires_the_keyboard_resize_action
    render_basic

    assert_selector "div[role='separator'][data-action*='keydown->resizable#onKeydown']"
    assert_selector "div[role='separator'][data-action*='mousedown->resizable#startDrag']"
  end

  # The accessible name is i18n-overridable.
  def test_custom_aria_label_names_every_splitter
    render_basic(aria_label: "Resize sidebar")

    assert_selector "div[role='separator'][aria-label='Resize sidebar']"
  end

  # The decorative grip is hidden from AT — the role/label already name the control.
  def test_grip_is_decorative
    render_basic

    assert_selector "div[role='separator'] div[aria-hidden='true']"
  end

  # The root is wired to the resizable controller with the direction value.
  def test_root_is_wired_to_the_controller
    render_basic(direction: :vertical)

    assert_selector "div[data-controller='resizable'][data-resizable-direction-value='vertical']"
  end

  # fail loud on an unknown direction rather than silently defaulting.
  def test_fails_loud_on_unknown_direction
    assert_raises(ArgumentError) do
      render_inline(UI::ResizableComponent.new(direction: :diagonal)) do |r|
        r.with_panel { "a" }
        r.with_panel { "b" }
      end
    end
  end

  # Regression guard: the box-shadow ring anti-pattern must never come back.
  def test_no_box_shadow_ring_or_outline_none
    render_basic
    html = page.native.to_html

    refute_includes html, "focus-visible:ring-"
    refute_includes html, "outline-none"
  end

  # The `data-[direction=…]` arbitrary variants compile onto the handle.
  def test_handle_carries_the_direction_arbitrary_variants
    render_basic

    assert_selector "div[role='separator'][class*='data-[direction=horizontal]:cursor-col-resize']"
  end

  # html_attrs pass through onto the root.
  def test_passes_through_html_attrs_onto_the_root
    render_inline(UI::ResizableComponent.new(id: "split", data: {testid: "rz"})) do |r|
      r.with_panel { "a" }
      r.with_panel { "b" }
    end

    assert_selector "div#split[data-testid='rz'][data-controller='resizable']"
  end

  # A caller-supplied class merges onto the root without clobbering the wrapper tokens.
  def test_merges_caller_class_onto_the_root
    render_basic(class: "h-96")

    assert_selector "div.h-96.flex.rounded-lg"
  end
end
