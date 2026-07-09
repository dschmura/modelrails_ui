# frozen_string_literal: true

require "render_test_helper"
load_component "pagination", "pagination_component.rb.tt"

# STRUCTURE-only render spec (mirrors breadcrumb_render_test.rb). Pagination is a
# static nav; the app 0b proves axe-AAA in a real browser.
class PaginationRenderTest < ViewComponent::TestCase
  def render_pages(current: 3, total: 10)
    render_inline(UI::PaginationComponent.new(
      current_page: current, total_pages: total, url: ->(p) { "/posts?page=#{p}" }
    ))
  end

  def test_renders_a_pagination_nav_landmark
    render_pages

    assert_selector "nav[aria-label='Pagination'] ul", visible: :all
  end

  def test_marks_the_current_page_with_aria_current
    render_pages

    assert_selector "span[aria-current='page']", text: "3", visible: :all
  end

  def test_prev_and_next_are_labelled_links
    render_pages

    assert_selector "a[aria-label='Previous page']", visible: :all
    assert_selector "a[aria-label='Next page']", visible: :all
  end

  def test_single_page_renders_nothing
    render_inline(UI::PaginationComponent.new(current_page: 1, total_pages: 1, url: ->(p) { "/?page=#{p}" }))

    assert_no_selector "nav"
  end
end
