# frozen_string_literal: true

require "render_test_helper"
load_component "scroll_area", "scroll_area_component.rb.tt"
load_component "table", "table_component.rb.tt"

# STRUCTURE-only render specs for the SERVER-rendered table — the opposite of
# `data_table`, which sorts and filters in the browser over data already on the
# page. Here sorting, filtering and paging are the caller's business (a GET form,
# pagy), and the component owns the card, the slots and the scroll contract.
#
# Ported from the reference app, which has run this component in production shape
# since 2026-09-18 across four call sites.
class TableRenderTest < ViewComponent::TestCase
  def render_table(**opts)
    render_inline(UI::TableComponent.new(caption: "All widgets", **opts)) do |t|
      t.with_header { '<th scope="col">Name</th>'.html_safe }
      t.with_body { "<tr><td>Widget</td></tr>".html_safe }
      yield t if block_given?
    end
  end

  # --- caption: the table's accessible name ---------------------------------

  def test_caption_is_present_but_visually_hidden_by_default
    render_table

    assert_selector "table caption.sr-only", text: "All widgets", visible: :all
    assert_selector "thead tr th[scope=col]", text: "Name", visible: :all
    assert_selector "tbody tr td", text: "Widget", visible: :all
  end

  def test_caption_can_be_shown
    render_table(caption_visible: true)

    assert_selector "table caption:not(.sr-only)", text: "All widgets", visible: :all
  end

  # Not a default with a fallback: a table with no accessible name is the defect
  # this component exists to make impossible, so it refuses to render.
  def test_caption_is_required
    error = assert_raises(ArgumentError) { render_inline(UI::TableComponent.new(caption: "")) }

    assert_match(/caption/, error.message)
  end

  def test_nil_caption_is_refused_too
    assert_raises(ArgumentError) { render_inline(UI::TableComponent.new(caption: nil)) }
  end

  # --- size -----------------------------------------------------------------

  def test_size_is_exposed_on_the_wrapper_for_row_partials_to_key_off
    render_table(size: :compact)

    assert_selector "div[data-size=compact] table", visible: :all
  end

  def test_unknown_size_fails_loud
    error = assert_raises(ArgumentError) { UI::TableComponent.new(caption: "x", size: :huge) }

    assert_match(/size/, error.message)
  end

  # A caller's data: must not clobber data-size, or every row partial keying off
  # it silently changes shape.
  def test_caller_data_merges_instead_of_replacing_the_size
    render_table(data: {controller: "x"})

    assert_selector "div[data-size=default][data-controller=x]", visible: :all
  end

  # --- slots ----------------------------------------------------------------

  def test_toolbar_is_the_cards_top_band_above_the_table
    render_table { |t| t.with_toolbar { "Summary" } }

    assert_selector "div[data-slot=toolbar] + table", visible: :all
    assert_selector "div[data-slot=toolbar]", text: "Summary", visible: :all
  end

  def test_footer_sits_below_the_table_inside_the_card
    render_table { |t| t.with_footer { "Showing 1–1 of 1" } }

    assert_selector "table + div[data-slot=footer]", text: "Showing 1–1 of 1", visible: :all
  end

  def test_slots_are_optional
    render_table

    assert_no_selector "[data-slot=toolbar]", visible: :all
    assert_no_selector "[data-slot=footer]", visible: :all
  end

  # --- the scroll contract --------------------------------------------------

  # The part worth reading carefully. `scroll: :horizontal` wraps ONLY the
  # <table>, so a wide table scrolls under a toolbar and footer that stay put.
  # Wrapping the whole component instead carried the toolbar's controls and the
  # footer's pager off-screen with the columns at phone width.
  def test_scroll_region_wraps_only_the_table
    render_table(scroll: :horizontal) do |t|
      t.with_toolbar { "Summary" }
      t.with_footer { "Showing 1–1 of 1" }
    end

    assert_selector "div[data-slot=toolbar] + div[role=region] + div[data-slot=footer]", visible: :all
    assert_selector "div[role=region] table", visible: :all
  end

  # The ScrollArea contract: a focusable region, so a mouse-less user can reach
  # the overflow at all (WCAG 2.1.1).
  def test_scroll_region_is_a_focusable_named_region
    render_table(scroll: :horizontal)
    region = page.find("div[role=region]", visible: :all)

    assert_equal "0", region[:tabindex]
    assert_includes region[:class], "overflow-x-auto"
    assert_includes region[:class], "focus-ring"
  end

  # Named DIFFERENTLY from the caption on purpose: an identical name makes a
  # screen reader announce the same words twice, once for the region and once
  # for the table.
  #
  # The assertion is against the INLINE English default, not against I18n.t with
  # no default: the delegate locale file is host-owned and not loaded here, and
  # the contract is that deleting a key degrades to English rather than to
  # "translation missing". `test_lists_the_scroll_region_key_in_the_delegate_file`
  # in the structural lane is what holds the key itself.
  def test_scroll_region_name_is_distinct_from_the_caption
    render_table(scroll: :horizontal)
    region = page.find("div[role=region]", visible: :all)

    assert_equal "All widgets, scrolls sideways", region["aria-label"]
    refute_equal "All widgets", region["aria-label"]
    assert_includes region["aria-label"], "All widgets"
  end

  # The key is overridable by a host: a translated caption must be able to carry
  # a translated region name with it.
  def test_scroll_region_name_honours_a_host_translation
    I18n.backend.store_translations(:en, modelrails_ui: {table: {scroll_region: "%{name} (swipe)"}})
    render_table(scroll: :horizontal)

    assert_equal "All widgets (swipe)", page.find("div[role=region]", visible: :all)["aria-label"]
  ensure
    I18n.backend.reload!
  end

  def test_no_scroll_region_by_default
    render_table

    assert_no_selector "[role=region]", visible: :all
    assert_selector "div[data-size] > table", visible: :all
  end

  def test_unknown_scroll_value_fails_loud
    error = assert_raises(ArgumentError) { UI::TableComponent.new(caption: "x", scroll: :vertical) }

    assert_match(/scroll/, error.message)
  end

  # --- the card -------------------------------------------------------------

  # A shared constant, so a caller's sortable header cell can match a plain one
  # instead of re-deriving the classes and drifting.
  def test_header_cell_classes_are_a_shared_constant
    assert_includes UI::TableComponent::TH, "h-11"
    assert_includes UI::TableComponent::TH, "text-left"
  end

  # The port-time decision, pinned: a filled card on the list_group's surface,
  # so a table and a list group sitting side by side read as the same kind of
  # container. See docs/components/table.md.
  def test_wrapper_is_a_filled_card_on_the_list_group_surface
    assert_match(/\bbg-surface\b/, UI::TableComponent::WRAPPER)
    refute_includes UI::TableComponent::WRAPPER, "bg-surface-raised"
  end

  def test_caller_class_merges_onto_the_card
    render_table(class: "mt-4")

    assert_selector "div.mt-4", visible: :all
  end
end
