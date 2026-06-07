# frozen_string_literal: true

require "render_test_helper"
require "securerandom"
load_component "dropdown_menu", "dropdown_menu_component.rb.tt"

# STRUCTURE-only render specs. The `menu` controller's BEHAVIOR (open/close, roving
# tabindex, type-ahead, Escape/Tab/outside-click dismissal + focus restoration) is
# proven by the app 0b browser spec (spec/system/ui/dropdown_menu_component_spec.rb) —
# the render harness cannot exercise JS, so here we assert the static scaffolding the
# controller drives.
class DropdownMenuRenderTest < ViewComponent::TestCase
  def render_menu(**opts)
    render_inline(UI::DropdownMenuComponent.new(**opts)) do |c|
      c.with_trigger { "Actions" }
      c.with_item { "Edit" }
      c.with_item(disabled: true) { "Archive" }
      c.with_item(separator: true)
      c.with_item(href: "/x") { "Open in new tab" }
    end
  end

  def test_wrapper_wires_the_menu_controller_and_outside_click
    render_menu(id: "m1")

    assert_selector "div[data-controller='menu']" \
                    "[data-action~='click@document->menu#closeOnClickOutside']" \
                    "[style*='anchor-name: --m1']", visible: :all
  end

  def test_trigger_is_a_real_button_with_menu_aria
    render_menu(id: "m2")

    assert_selector "button[type='button'][id='m2-trigger'][aria-haspopup='menu']" \
                    "[aria-expanded='false'][aria-controls='m2'][data-menu-target='trigger']" \
                    "[data-action~='click->menu#toggle'][data-action~='keydown->menu#triggerKeydown']",
      text: "Actions", visible: :all
  end

  def test_menu_panel_is_labelled_by_the_trigger_and_hidden
    render_menu(id: "m3")

    assert_selector "div#m3[role='menu'][aria-labelledby='m3-trigger'][tabindex='-1'][hidden]" \
                    "[data-menu-target='menu'][data-action~='keydown->menu#navigate']" \
                    "[style*='position-anchor: --m3']", visible: :all
  end

  def test_items_are_menuitems_with_roving_tabindex_and_activate_action
    render_menu

    assert_selector "button[role='menuitem'][type='button'][tabindex='-1']" \
                    "[data-menu-target='item'][data-action~='click->menu#activate']",
      text: "Edit", visible: :all
  end

  def test_disabled_item_is_aria_disabled
    render_menu

    assert_selector "[role='menuitem'][aria-disabled='true']", text: "Archive", visible: :all
  end

  def test_separator_item_renders_a_separator_role
    render_menu

    assert_selector "div[role='separator']", visible: :all
  end

  def test_href_item_renders_an_anchor_menuitem
    render_menu

    assert_selector "a[role='menuitem'][href='/x'][data-menu-target='item']",
      text: "Open in new tab", visible: :all
  end

  def test_icon_only_trigger_takes_an_aria_label
    render_inline(UI::DropdownMenuComponent.new(aria_label: "Row actions")) do |c|
      c.with_trigger { "⋮" }
      c.with_item { "Edit" }
    end

    assert_selector "button[aria-haspopup='menu'][aria-label='Row actions']", visible: :all
  end

  def test_requires_a_trigger_slot
    error = assert_raises(ArgumentError) do
      render_inline(UI::DropdownMenuComponent.new) { |c| c.with_item { "Edit" } }
    end
    assert_match(/with_trigger/, error.message)
  end

  def test_fail_loud_on_unknown_side
    assert_raises(ArgumentError) { UI::DropdownMenuComponent.new(side: :diagonal) }
  end

  def test_fail_loud_on_unknown_align
    assert_raises(ArgumentError) { UI::DropdownMenuComponent.new(align: :middle) }
  end

  def test_item_merges_caller_data_without_clobbering_wiring
    render_inline(UI::DropdownMenuComponent.new) do |c|
      c.with_trigger { "Actions" }
      c.with_item(data: {turbo_frame: "modal"}) { "Edit" }
    end

    assert_selector "button[role='menuitem'][data-menu-target='item']" \
                    "[data-action~='click->menu#activate'][data-turbo-frame='modal']",
      text: "Edit", visible: :all
  end

  def test_item_cannot_override_reserved_aria_wiring
    render_inline(UI::DropdownMenuComponent.new) do |c|
      c.with_trigger { "Actions" }
      c.with_item(role: "option", tabindex: "0") { "Edit" }
    end

    assert_selector "[role='menuitem'][tabindex='-1']", text: "Edit", visible: :all
    assert_no_selector "[role='option']", visible: :all
  end

  def test_component_data_and_style_do_not_clobber_wiring
    render_inline(UI::DropdownMenuComponent.new(id: "m9", data: {turbo_frame: "x"}, style: "color: red")) do |c|
      c.with_trigger { "Actions" }
      c.with_item { "Edit" }
    end

    assert_selector "div[data-controller='menu']" \
                    "[data-action~='click@document->menu#closeOnClickOutside']" \
                    "[data-turbo-frame='x']" \
                    "[style*='anchor-name: --m9'][style*='color: red']", visible: :all
  end
end
