# frozen_string_literal: true

require "render_test_helper"
load_component "speed_dial", "speed_dial_component.rb.tt"

# STRUCTURE-only render specs. The disclosure behavior (toggle, aria-expanded sync to
# the open state, outside-click dismissal, icon rotation) is driven by the `speed-dial`
# Stimulus controller and proven by the app 0b browser spec — the render harness can't
# exercise JS, so here we assert the static scaffolding + the focus/disclosure contract.
class SpeedDialRenderTest < ViewComponent::TestCase
  def render_dial(**opts)
    render_inline(UI::SpeedDialComponent.new(**opts)) do |dial|
      dial.with_action(label: "New document", href: "/docs/new")
      dial.with_action(label: "Upload")
    end
  end

  def test_renders_a_div_wired_to_the_speed_dial_controller
    render_dial

    assert_selector "div[data-controller='speed-dial']" \
                    "[data-action~='click@document->speed-dial#closeOnClickOutside']",
      visible: :all
  end

  # The FAB is a disclosure trigger: focus-ring + aria-expanded + i18n accessible name,
  # wired to toggle the controller.
  def test_fab_is_an_i18n_labelled_disclosure_trigger_with_the_focus_ring
    render_dial

    assert_selector "button.focus-ring[type='button']" \
                    "[aria-expanded='false'][aria-controls][aria-label='Open actions']" \
                    "[data-speed-dial-target='fab'][data-action~='click->speed-dial#toggle']",
      visible: :all
  end

  def test_custom_label_names_the_fab
    render_dial(label: "Quick actions")

    assert_selector "button[aria-label='Quick actions']", visible: :all
  end

  # aria-controls points at the hidden action panel's id (disclosure target).
  def test_fab_controls_the_hidden_action_panel
    render_dial

    button = page.find("button[data-speed-dial-target='fab']", visible: :all)
    panel_id = button["aria-controls"]

    assert_selector "div##{panel_id}[data-speed-dial-target='panel'][hidden]", visible: :all
  end

  # The decorative + glyph is hidden from the accessibility tree.
  def test_plus_icon_is_decorative
    render_dial

    assert_selector "svg[aria-hidden='true'][data-speed-dial-target='icon']", visible: :all
  end

  # Every action carries the AAA offset focus-ring; a href renders an <a>, no href a <button>.
  def test_actions_are_focusable_links_or_buttons_with_the_focus_ring
    render_dial

    assert_selector "div[data-speed-dial-target='panel'] a.focus-ring[href='/docs/new']",
      text: "New document", visible: :all
    assert_selector "div[data-speed-dial-target='panel'] button.focus-ring[type='button']",
      text: "Upload", visible: :all
  end

  def test_unknown_position_raises
    assert_raises(ArgumentError) do
      render_inline(UI::SpeedDialComponent.new(position: :bogus))
    end
  end

  def test_known_positions_render
    %i[bottom_right bottom_left bottom_center].each do |pos|
      render_inline(UI::SpeedDialComponent.new(position: pos))

      assert_selector "div[data-controller='speed-dial']", visible: :all
    end
  end

  # Regression guard: the ring anti-pattern must never come back.
  def test_no_box_shadow_ring_or_outline_none
    render_dial
    html = page.native.to_html

    refute_includes html, "focus-visible:ring-"
    refute_includes html, "outline-none"
  end

  # html_attrs pass through onto the root <div>.
  def test_passes_through_html_attrs_onto_the_root
    render_inline(UI::SpeedDialComponent.new(id: "page-fab", data: {testid: "sd"}))

    assert_selector "div#page-fab[data-testid='sd'][data-controller='speed-dial']", visible: :all
  end

  # A caller-supplied class merges onto the root without clobbering the position token.
  def test_merges_caller_class_onto_the_root
    render_inline(UI::SpeedDialComponent.new(class: "z-10"))

    assert_selector "div.z-10[data-controller='speed-dial']", visible: :all
  end

  # Caller data: merges UNDER the controller wiring — it must not clobber it.
  def test_caller_data_merges_without_clobbering_the_controller
    render_inline(UI::SpeedDialComponent.new(data: {turbo_frame: "f"}))

    assert_selector "div[data-controller='speed-dial'][data-turbo-frame='f']", visible: :all
  end
end
