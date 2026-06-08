# frozen_string_literal: true

require "render_test_helper"
require "securerandom"
load_component "context_menu", "context_menu_component.rb.tt"

# STRUCTURE-only render specs. The behavior (right-click + Shift+F10 open, roving
# tabindex, type-ahead, Escape/Tab/outside-click dismissal) is proven by the app 0b
# browser spec (spec/system/ui/context_menu_component_spec.rb) — the render harness
# cannot exercise JS, so here we assert the static scaffolding the `menu` controller drives.
class ContextMenuRenderTest < ViewComponent::TestCase
  def render_menu(**opts)
    render_inline(UI::ContextMenuComponent.new(**opts)) do |c|
      c.with_trigger { "Right-click me" }
      c.with_item { "Edit" }
      c.with_item(disabled: true) { "Archive" }
      c.with_item(separator: true)
      c.with_item(href: "/x") { "Open in new tab" }
    end
  end

  def test_wrapper_wires_the_menu_controller_and_outside_click
    render_menu

    assert_selector "div[data-controller='menu']" \
                    "[data-action~='click@document->menu#closeOnClickOutside']", visible: :all
  end

  def test_trigger_region_is_a_focusable_menu_host
    render_menu(id: "c1")

    assert_selector "div[id='c1-trigger'][tabindex='0'][aria-haspopup='menu']" \
                    "[aria-expanded='false'][aria-controls='c1'][data-menu-target='trigger']" \
                    "[data-action~='contextmenu->menu#openAt'][data-action~='keydown->menu#openContextKey']",
      text: "Right-click me", visible: :all
  end

  def test_menu_panel_is_a_fixed_labelled_menu_hidden_until_open
    render_menu(id: "c2")

    assert_selector "div#c2[role='menu'][aria-labelledby='c2-trigger'][tabindex='-1'][hidden]" \
                    "[data-menu-target='menu'][data-action~='keydown->menu#navigate']" \
                    ".fixed", visible: :all
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

  def test_explicit_label_sets_aria_label_and_drops_labelledby
    render_inline(UI::ContextMenuComponent.new(label: "Row actions")) do |c|
      c.with_trigger { "Row" }
      c.with_item { "Edit" }
    end

    assert_selector "[role='menu'][aria-label='Row actions']", visible: :all
    assert_no_selector "[role='menu'][aria-labelledby]", visible: :all
  end

  def test_item_merges_caller_data_without_clobbering_wiring
    render_inline(UI::ContextMenuComponent.new) do |c|
      c.with_trigger { "Right-click me" }
      c.with_item(data: {turbo_frame: "modal"}) { "Edit" }
    end

    assert_selector "button[role='menuitem'][data-menu-target='item']" \
                    "[data-action~='click->menu#activate'][data-turbo-frame='modal']",
      text: "Edit", visible: :all
  end

  def test_requires_a_trigger_slot
    error = assert_raises(ArgumentError) do
      render_inline(UI::ContextMenuComponent.new) { |c| c.with_item { "Edit" } }
    end
    assert_match(/with_trigger/, error.message)
  end

  def test_item_cannot_override_reserved_aria_wiring
    render_inline(UI::ContextMenuComponent.new) do |c|
      c.with_trigger { "Right-click me" }
      c.with_item(role: "option", tabindex: "0") { "Edit" }
    end

    assert_selector "[role='menuitem'][tabindex='-1']", text: "Edit", visible: :all
    assert_no_selector "[role='option']", visible: :all
  end

  def test_component_data_does_not_clobber_wrapper_wiring
    render_inline(UI::ContextMenuComponent.new(data: {turbo_frame: "x"})) do |c|
      c.with_trigger { "Right-click me" }
      c.with_item { "Edit" }
    end

    assert_selector "div[data-controller='menu']" \
                    "[data-action~='click@document->menu#closeOnClickOutside']" \
                    "[data-turbo-frame='x']", visible: :all
  end
end
