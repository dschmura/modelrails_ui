# frozen_string_literal: true

require "render_test_helper"
load_component "list_group", "list_group_component.rb.tt"
load_component "list_group", "list_group_item_component.rb.tt"

# STRUCTURE-only render specs. The app 0b preview-host spec proves AAA contrast in a
# real browser; here we assert the semantic scaffolding: a <ul> of <li>, link rows as
# <a> inside <li> with the focus-ring utility, aria-current on the active link, AAA
# tokens, and caller-class merge.
class ListGroupRenderTest < ViewComponent::TestCase
  # Render an item to an HTML-safe string so it can be composed inside the group's
  # block, mirroring how views nest `ui :list_group_item` inside `ui :list_group`.
  def render_item(*args, **kwargs)
    UI::ListGroupItemComponent.new(*args, **kwargs).render_in(vc_test_controller.view_context)
  end

  def test_renders_a_ul_with_li_items
    items = render_item("Dashboard") + render_item("Settings")
    render_inline(UI::ListGroupComponent.new) { items }

    assert_selector "ul > li", text: "Dashboard"
    assert_selector "ul > li", text: "Settings"
  end

  def test_group_uses_aaa_surface_tokens
    render_inline(UI::ListGroupComponent.new)

    assert_selector "ul.bg-surface.border-border"
    assert_selector "ul.divide-border"
  end

  def test_static_item_is_a_plain_non_focusable_li
    render_inline(UI::ListGroupItemComponent.new("Billing"))

    assert_selector "li.text-text-heading", text: "Billing"
    assert_no_selector "a"
  end

  def test_muted_item_uses_the_aaa_muted_token
    render_inline(UI::ListGroupItemComponent.new("Help", variant: :muted))

    assert_selector "li.text-text-muted", text: "Help"
  end

  def test_link_item_is_an_anchor_inside_an_li_with_focus_ring
    render_inline(UI::ListGroupItemComponent.new("Home", href: "/"))

    assert_selector "li > a[href='/'].focus-ring", text: "Home"
  end

  def test_active_link_carries_aria_current_and_the_solid_fill
    render_inline(UI::ListGroupItemComponent.new("Profile", href: "/profile", active: true))

    assert_selector "a[aria-current='page'].bg-interactive.text-text-on-interactive", text: "Profile"
  end

  def test_inactive_link_has_no_aria_current
    render_inline(UI::ListGroupItemComponent.new("Logout", href: "/logout"))

    assert_no_selector "[aria-current]"
  end

  def test_slot_content_takes_precedence_over_the_label
    render_inline(UI::ListGroupItemComponent.new("ignored")) { "Alice" }

    assert_selector "li", text: "Alice"
    assert_no_text "ignored"
  end

  def test_merges_caller_classes
    render_inline(UI::ListGroupItemComponent.new("X", class: "mt-2"))

    assert_selector "li.mt-2"
  end

  def test_unknown_variant_fails_loud
    assert_raises(ArgumentError) do
      render_inline(UI::ListGroupItemComponent.new("X", variant: :bogus))
    end
  end
end
