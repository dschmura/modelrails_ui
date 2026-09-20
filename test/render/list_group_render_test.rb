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

  # --- list semantics (#190) ------------------------------------------------

  # Tailwind's preflight sets `list-style: none` on `ul`, and Safari/VoiceOver
  # drops the implicit list role when the marker is gone — so the role has to be
  # explicit. axe has no rule for this, so a clean axe run proves nothing here.
  def test_group_is_an_explicit_list
    render_inline(UI::ListGroupComponent.new)

    assert_selector "ul[role=list]"
    assert_equal 1, role_attribute_count, "expected exactly one role attribute"
  end

  # A caller who means something other than a plain list (a navigation, say) must
  # win — and must not end up with BOTH roles on the element.
  def test_symbol_key_role_override_wins_and_is_emitted_once
    render_inline(UI::ListGroupComponent.new(role: "navigation"))

    assert_selector "ul[role=navigation]"
    assert_no_selector "ul[role=list]"
    assert_equal 1, role_attribute_count, "expected exactly one role attribute"
  end

  # The non-negotiable one. `content_tag` does NOT de-duplicate a symbol `:role`
  # against a string `"role"` — it emits both, raises nothing, and the winner
  # becomes browser-dependent. Presence assertions pass on that broken output,
  # so this counts the attribute in the RAW string, before Nokogiri collapses it.
  def test_string_key_role_override_wins_and_is_emitted_once
    render_inline(UI::ListGroupComponent.new("role" => "navigation"))

    assert_equal 1, role_attribute_count,
      "duplicate role attribute in: #{rendered_content}"
    assert_includes rendered_content, 'role="navigation"'
    refute_includes rendered_content, 'role="list"'
  end

  def role_attribute_count = rendered_content.scan(/\srole=/).length

  def test_group_uses_aaa_surface_tokens
    render_inline(UI::ListGroupComponent.new)

    assert_selector "ul.bg-surface-raised.border-border"
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

  # Hover is bound to interactivity, not to colour variant (#191/#197). A static
  # row is a plain <li> the docblock calls "never focusable"; a full-width
  # highlight on it promises a click target that does not exist.
  def test_a_static_row_does_not_highlight_on_hover
    render_inline(UI::ListGroupItemComponent.new("Billing"))

    assert_no_selector 'li[class~="hover:bg-surface-sunken"]'
  end

  def test_a_static_muted_row_does_not_highlight_on_hover
    render_inline(UI::ListGroupItemComponent.new("Help", variant: :muted))

    assert_no_selector 'li[class~="hover:bg-surface-sunken"]'
  end

  # The other half of the same rule: a row that IS interactive still highlights,
  # so the fix cannot be "delete the hover".
  def test_a_link_row_does_highlight_on_hover
    render_inline(UI::ListGroupItemComponent.new("Home", href: "/"))

    assert_selector 'a[class~="hover:bg-surface-sunken"]'
  end

  # Regression guard, in the shape ToggleComponent already uses: hover must NOT
  # be hoisted into LINK wholesale. LINK applies to active rows too, and an
  # active row hovering to bg-surface-sunken keeps text-text-on-interactive —
  # white text on a near-white surface in the light theme.
  def test_an_active_link_row_never_hovers_to_the_sunken_surface
    render_inline(UI::ListGroupItemComponent.new("Profile", href: "/profile", active: true))

    assert_no_selector 'a[class~="hover:bg-surface-sunken"]'
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

  # `active` marks the current page among navigable rows. Without `href:` the row
  # is a plain <li> wearing the solid interactive fill — the strongest "this is the
  # current, actionable thing" signal the system has — on something that cannot be
  # focused or activated, and that `static_row` correctly refuses to give
  # `aria-current`. So it looks current to sighted users and is silent to assistive
  # technology. Detectable misuse, so it fails loud like an unknown variant (#196).
  def test_active_without_href_fails_loud
    error = assert_raises(ArgumentError) do
      render_inline(UI::ListGroupItemComponent.new("Billing", active: true))
    end

    assert_match(/href/, error.message)
  end

  # The other half of the posture: a bad flag must not 500 a production page.
  def test_active_without_href_degrades_instead_of_raising_in_production
    with_production_rails_env do
      render_inline(UI::ListGroupItemComponent.new("Billing", active: true))
    end

    assert_selector "li.text-text-heading", text: "Billing"
    assert_no_selector "li.bg-interactive"
  end

  # Guard: the legitimate combination is untouched.
  def test_active_with_href_is_still_the_current_page
    render_inline(UI::ListGroupItemComponent.new("Profile", href: "/profile", active: true))

    assert_selector "li > a.bg-interactive[aria-current='page']", text: "Profile"
  end

  private

  # This harness is deliberately Rails-less — `rails/generators` defines Rails
  # without `Rails.env` — so the production branch is unreachable unless Rails is
  # given an env for the duration. Without this the degrade half is unproven.
  def with_production_rails_env
    env = Object.new
    def env.production? = true
    Rails.define_singleton_method(:env) { env }
    yield
  ensure
    Rails.singleton_class.send(:remove_method, :env)
  end
end
