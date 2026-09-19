# frozen_string_literal: true

require "render_test_helper"
require "active_support/core_ext/string/output_safety"
load_component "error_summary", "error_summary_component.rb.tt"

class ErrorSummaryRenderTest < ViewComponent::TestCase
  ITEMS = [
    {message: "Title can't be blank", href: "#article_title"},
    {message: "Body is too short", href: "#article_body"}
  ].freeze

  def test_renders_nothing_with_no_items
    render_inline(UI::ErrorSummaryComponent.new(items: []))

    assert_no_selector "div"
  end

  def test_container_is_a_focusable_autofocused_alert
    # tabindex=-1 makes the div programmatically focusable; autofocus is what
    # actually moves focus — browsers honour it on load and Turbo Drive re-honours
    # it after every render, including 422 form re-renders. Zero JS.
    render_inline(UI::ErrorSummaryComponent.new(items: ITEMS))

    assert_selector "div[role='alert'][tabindex='-1'][autofocus]"
  end

  def test_each_item_links_to_its_field
    render_inline(UI::ErrorSummaryComponent.new(items: ITEMS))

    assert_selector "li a[href='#article_title']", text: "Title can't be blank"
    assert_selector "li a[href='#article_body']", text: "Body is too short"
  end

  def test_item_without_href_renders_as_plain_text
    render_inline(UI::ErrorSummaryComponent.new(items: [{message: "Something broke", href: nil}]))

    assert_selector "li", text: "Something broke"
    assert_no_selector "li a"
  end

  def test_heading_is_pluralized_and_level_is_configurable
    render_inline(UI::ErrorSummaryComponent.new(items: ITEMS, heading_level: 3))

    assert_selector "h3", text: "2 errors prevented this from being saved"
    assert_no_selector "h2"
  end

  def test_heading_singular
    render_inline(UI::ErrorSummaryComponent.new(items: ITEMS.first(1)))

    assert_selector "h2", text: "1 error prevented this from being saved"
  end

  def test_heading_level_out_of_range_raises
    assert_raises(ArgumentError) { UI::ErrorSummaryComponent.new(items: ITEMS, heading_level: 7) }
  end

  def test_icon_is_inline_svg_and_hidden_from_assistive_tech
    render_inline(UI::ErrorSummaryComponent.new(items: ITEMS))

    assert_selector "svg[aria-hidden='true']"
  end

  # --- target size (#187) ----------------------------------------------------

  # Each link sits alone in a list item rather than inside running text, so it is
  # a target in its own right: a bare `underline focus-ring` anchor renders 17px
  # tall and fails axe's target-size (24px AA) as well as the 44px AAA floor. The
  # host app measured this with a live audit; the gem's CI cannot, so the floor is
  # asserted in markup here.
  def test_link_items_meet_the_target_size_floor
    render_inline(UI::ErrorSummaryComponent.new(items: [{message: "Email is invalid", href: "#user_email"}]))
    link = page.find("a[href='#user_email']", visible: :all)

    assert_includes link[:class], "min-h-11"
    assert_includes link[:class], "inline-flex"
    assert_includes link[:class], "items-center"
  end

  # The floor must not cost the affordance: the link stays underlined and keeps
  # the AAA offset outline.
  def test_link_items_keep_their_underline_and_focus_ring
    render_inline(UI::ErrorSummaryComponent.new(items: [{message: "Email is invalid", href: "#user_email"}]))
    link = page.find("a[href='#user_email']", visible: :all)

    assert_includes link[:class], "underline"
    assert_includes link[:class], "focus-ring"
  end

  # The marker is why this component is the one documented exemption from the
  # role="list" sweep, so it is pinned here rather than left implicit.
  def test_the_list_keeps_its_marker
    render_inline(UI::ErrorSummaryComponent.new(items: [{message: "Email is invalid", href: "#user_email"}]))

    assert_selector "ul.list-disc.list-inside", visible: :all
  end
end
