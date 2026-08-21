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
end
