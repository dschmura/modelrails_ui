# frozen_string_literal: true

require "render_test_helper"
require "securerandom"
load_component "menubar", "menubar_menu_component.rb.tt"
load_component "menubar", "menubar_component.rb.tt"

# STRUCTURE-only render specs. The behavior (roving, ←/→ follow, submenu open/close, the
# outlet coordination) is proven by the app 0b browser spec — the render harness cannot
# exercise JS or Stimulus outlets, so here we assert the static scaffolding both controllers
# rely on.
class MenubarRenderTest < ViewComponent::TestCase
  def render_bar
    render_inline(UI::MenubarComponent.new(label: "Main")) do |bar|
      bar.with_menu(label: "File") do |m|
        m.with_item { "New" }
        m.with_item(disabled: true) { "Archive" }
        m.with_item(separator: true)
        m.with_item(href: "/x") { "Open recent" }
      end
      bar.with_menu(label: "Edit") do |m|
        m.with_item { "Undo" }
      end
    end
  end

  def test_bar_is_a_menubar_wired_to_the_menubar_controller_with_the_menu_outlet
    render_bar

    assert_selector "div[role='menubar'][aria-label='Main']" \
                    "[data-controller='menubar']" \
                    "[data-menubar-menu-outlet='[data-menubar-item]']" \
                    "[data-action~='keydown->menubar#navigate'][data-action~='focusin->menubar#syncRoving']",
      visible: :all
  end

  def test_each_menu_is_a_menu_controller_outlet_target
    render_bar

    assert_selector "div[data-controller='menu'][data-menubar-item]", count: 2, visible: :all
  end

  def test_each_submenu_wrapper_dismisses_on_outside_click
    render_bar

    assert_selector "div[data-controller='menu'][data-menubar-item]" \
                    "[data-action~='click@document->menu#closeOnClickOutside']",
      count: 2, visible: :all
  end

  def test_bar_item_is_a_menuitem_button_that_triggers_its_menu
    render_bar

    assert_selector "button[role='menuitem'][type='button'][aria-haspopup='menu'][aria-expanded='false']" \
                    "[tabindex='-1'][data-menu-target='trigger'][data-menubar-target='item']" \
                    "[data-action~='click->menu#toggle'][data-action~='keydown->menu#triggerKeydown']",
      text: "File", visible: :all
  end

  def test_bar_item_controls_its_submenu_and_carries_an_anchor_name
    render_bar

    button = page.find("button", text: "File", visible: :all)
    panel_id = button["aria-controls"]

    assert_includes button["style"], "anchor-name: --#{panel_id}"
    assert_selector "div##{panel_id}[role='menu'][aria-labelledby='#{button["id"]}'][hidden]" \
                    "[data-menu-target='menu'][data-action~='keydown->menu#navigate']" \
                    "[style*='position-anchor: --#{panel_id}']", visible: :all
  end

  def test_submenu_items_are_menuitems_with_roving_tabindex
    render_bar

    assert_selector "button[role='menuitem'][tabindex='-1'][data-menu-target='item']" \
                    "[data-action~='click->menu#activate']", text: "New", visible: :all
  end

  def test_submenu_disabled_separator_href_variants
    render_bar

    assert_selector "[role='menuitem'][aria-disabled='true']", text: "Archive", visible: :all
    assert_selector "div[role='separator']", visible: :all
    assert_selector "a[role='menuitem'][href='/x'][data-menu-target='item']", text: "Open recent", visible: :all
  end

  def test_submenu_panel_uses_anchor_positioning
    render_bar

    assert_selector "[data-menu-target='menu'][class*='position-try-fallbacks:flip-block']", visible: :all
    assert_selector "[data-menu-target='menu'][class*='position-area:bottom_span-right']", visible: :all
  end

  def test_menubar_requires_a_label
    assert_raises(ArgumentError) { UI::MenubarComponent.new }
  end

  def test_menubar_passes_class_through
    render_inline(UI::MenubarComponent.new(label: "Main", class: "w-full")) do |bar|
      bar.with_menu(label: "File") { |m| m.with_item { "New" } }
    end

    assert_selector "div[role='menubar'][aria-label='Main'][class~='w-full']", visible: :all
  end

  def test_menubar_merges_caller_data_without_clobbering_the_coordinator
    render_inline(UI::MenubarComponent.new(label: "Main", data: {turbo_frame: "x"})) do |bar|
      bar.with_menu(label: "File") { |m| m.with_item { "New" } }
    end

    assert_selector "div[role='menubar'][data-controller='menubar']" \
                    "[data-menubar-menu-outlet='[data-menubar-item]']" \
                    "[data-action~='keydown->menubar#navigate'][data-turbo-frame='x']",
      visible: :all
  end

  def test_menubar_menu_requires_a_label
    assert_raises(ArgumentError) { UI::MenubarMenuComponent.new }
  end

  def test_menubar_menu_wrapper_merges_caller_class_and_data
    render_inline(UI::MenubarComponent.new(label: "Main")) do |bar|
      bar.with_menu(label: "File", class: "shrink-0", data: {turbo_frame: "x"}) do |m|
        m.with_item { "New" }
      end
    end

    assert_selector "div[data-controller='menu'][data-menubar-item][data-turbo-frame='x']" \
                    "[class~='relative'][class~='shrink-0']", visible: :all
  end
end
