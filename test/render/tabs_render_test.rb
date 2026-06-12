# frozen_string_literal: true

require "render_test_helper"
require "securerandom"
load_component "tabs", "tabs_item_component.rb.tt"
load_component "tabs", "tabs_component.rb.tt"

# STRUCTURE-only render specs. The keyboard (←/→ activate+wrap, Home/End, skip-disabled, roving
# tabindex, focusable panels) is proven by the app 0b browser spec — the render harness cannot
# exercise JS, so here we assert the static scaffolding the controller relies on.
class TabsRenderTest < ViewComponent::TestCase
  def render_tabs(selected: 0)
    render_inline(UI::TabsComponent.new(label: "Account", selected: selected)) do |t|
      t.with_tab(title: "Profile") { "profile body" }
      t.with_tab(title: "Password", disabled: true) { "password body" }
      t.with_tab(title: "Notifications") { "notifications body" }
    end
  end

  def test_group_is_wired_to_the_tabs_controller
    render_tabs

    assert_selector "div[data-controller='tabs'][data-tabs-index-value='0']", visible: :all
  end

  def test_caller_data_merges_without_clobbering_the_controller
    render_inline(UI::TabsComponent.new(label: "Account", data: {turbo_frame: "f"})) do |t|
      t.with_tab(title: "Profile") { "profile body" }
    end

    assert_selector "div[data-controller='tabs'][data-tabs-index-value='0'][data-turbo-frame='f']", visible: :all
  end

  def test_tablist_has_role_and_accessible_name
    render_tabs

    assert_selector "div[role='tablist'][aria-label='Account'][aria-orientation='horizontal']", visible: :all
  end

  def test_each_tab_is_a_role_tab_button_wired_to_the_controller
    render_tabs

    assert_selector "button[role='tab'][type='button'][data-tabs-target='tab']" \
                    "[data-action~='click->tabs#select'][data-action~='keydown->tabs#navigate']",
      count: 3, visible: :all
  end

  def test_active_tab_has_roving_tabindex_zero_and_aria_selected
    render_tabs

    assert_selector "button[role='tab'][aria-selected='true'][tabindex='0'][data-state='active']",
      text: "Profile", visible: :all
    assert_selector "button[role='tab'][aria-selected='false'][tabindex='-1']",
      text: "Notifications", visible: :all
  end

  def test_disabled_tab_is_aria_disabled
    render_tabs

    assert_selector "button[role='tab'][aria-disabled='true']", text: "Password", visible: :all
  end

  def test_tab_and_panel_cross_reference_by_id
    render_tabs

    tab = page.find("button[role='tab']", text: "Profile", visible: :all)
    panel_id = tab["aria-controls"]

    assert_selector "div##{panel_id}[role='tabpanel'][aria-labelledby='#{tab["id"]}'][tabindex='0']" \
                    "[data-tabs-target='panel']", text: "profile body", visible: :all
  end

  def test_only_the_selected_panel_is_visible
    render_tabs(selected: 2)

    # active tab is Notifications (index 2); its panel is shown, the others hidden
    assert_selector "button[role='tab'][aria-selected='true']", text: "Notifications", visible: :all
    assert_selector "div[role='tabpanel']:not([hidden])", text: "notifications body", visible: :all
    assert_selector "div[role='tabpanel'][hidden]", text: "profile body", visible: :all
  end

  def test_tabs_requires_a_label
    assert_raises(ArgumentError) { UI::TabsComponent.new }
  end

  def test_tab_item_requires_a_title
    assert_raises(ArgumentError) { UI::TabsItemComponent.new }
  end
end
