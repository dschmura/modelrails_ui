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

  # tablist_class: merges onto the tablist bar (placement/styling — e.g. a
  # tablist floated over a media stage) without clobbering the base classes;
  # cn resolves conflicts in the caller's favor.
  def test_tablist_class_merges_onto_the_tablist
    render_inline(UI::TabsComponent.new(label: "Account", tablist_class: "w-full justify-start")) do |t|
      t.with_tab(title: "Profile") { "profile body" }
    end

    assert_selector "div[role='tablist'].w-full.justify-start.bg-surface-sunken", visible: :all
    assert_no_selector "div[role='tablist'].justify-center", visible: :all
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

  # orientation / activation — both default to what this component shipped with, so
  # existing call sites are unaffected. The controller reads the Stimulus values; the
  # keyboard behaviour itself is proven by the app browser spec.
  def test_orientation_defaults_to_horizontal
    render_tabs

    assert_selector "[data-tabs-orientation-value='horizontal']", visible: :all
  end

  def test_vertical_orientation_is_declared_and_restacks_the_bar
    render_inline(UI::TabsComponent.new(label: "Account", orientation: :vertical)) do |t|
      t.with_tab(title: "Profile") { "profile body" }
    end

    assert_selector "div[role='tablist'][aria-orientation='vertical'].flex-col", visible: :all
    assert_selector "[data-tabs-orientation-value='vertical']", visible: :all
  end

  def test_activation_defaults_to_automatic
    render_tabs

    assert_selector "[data-tabs-activation-value='automatic']", visible: :all
  end

  def test_manual_activation_is_declared
    render_inline(UI::TabsComponent.new(label: "Account", activation: :manual)) do |t|
      t.with_tab(title: "Profile") { "profile body" }
    end

    assert_selector "[data-tabs-activation-value='manual']", visible: :all
  end

  # tablist_class still merges when the bar restacks — the vertical base class set is a
  # different constant, so this is the case a naive swap would drop.
  def test_tablist_class_merges_onto_a_vertical_tablist
    render_inline(UI::TabsComponent.new(label: "Account", orientation: :vertical, tablist_class: "w-48")) do |t|
      t.with_tab(title: "Profile") { "profile body" }
    end

    assert_selector "div[role='tablist'].w-48.flex-col.bg-surface-sunken", visible: :all
  end

  def test_unknown_orientation_raises
    error = assert_raises(ArgumentError) { UI::TabsComponent.new(label: "Account", orientation: :diagonal) }

    assert_match(/orientation/, error.message)
  end

  def test_unknown_activation_raises
    error = assert_raises(ArgumentError) { UI::TabsComponent.new(label: "Account", activation: :telepathic) }

    assert_match(/activation/, error.message)
  end
end
