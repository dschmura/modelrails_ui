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

  # The focus target and the alert are DIFFERENT nodes, deliberately (GOV.UK's
  # error-summary shape). When one element is both, a reader can announce it
  # twice — once as the alert, once as the newly focused element. Splitting them
  # lets focus land on a role-less container that reads its contents once, while
  # the alert inside keeps its semantics for readers that use it.
  #
  # tabindex=-1 makes the container programmatically focusable; autofocus is what
  # actually moves focus — browsers honour it on load and Turbo Drive re-honours
  # it after every render, including 422 form re-renders. Zero JS.
  def test_focus_target_is_the_container_and_carries_no_role
    render_inline(UI::ErrorSummaryComponent.new(items: ITEMS))

    assert_selector "div[data-slot='error-summary'][tabindex='-1'][autofocus]"
    assert_no_selector "div[data-slot='error-summary'][role='alert']"
  end

  def test_the_alert_is_a_separate_node_inside_the_focus_target
    render_inline(UI::ErrorSummaryComponent.new(items: ITEMS))

    assert_selector "div[data-slot='error-summary'] div[role='alert']"
  end

  # The pair is what matters: exactly one alert, and it is never the focused node.
  def test_there_is_exactly_one_alert_and_it_is_not_focusable
    render_inline(UI::ErrorSummaryComponent.new(items: ITEMS))

    assert_selector "[role='alert']", count: 1
    assert_no_selector "[role='alert'][tabindex]"
    assert_no_selector "[role='alert'][autofocus]"
  end

  # The heading and the items must sit INSIDE the alert, or the live region
  # announces an empty container.
  def test_the_alert_contains_the_heading_and_the_items
    render_inline(UI::ErrorSummaryComponent.new(items: ITEMS))

    within_alert = page.find("[role='alert']")

    assert within_alert.has_css?("h2"), "heading is outside the alert"
    assert within_alert.has_css?("li a[href='#article_title']"), "items are outside the alert"
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

    assert_includes link[:class], "min-h-input"
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
