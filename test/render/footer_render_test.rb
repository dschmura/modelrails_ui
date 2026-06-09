# frozen_string_literal: true

require "render_test_helper"
load_component "footer", "footer_component.rb.tt"

class FooterRenderTest < ViewComponent::TestCase
  COLUMNS = [
    {title: "Product", links: [{label: "Features", href: "/features"}, {label: "Pricing", href: "/pricing"}]},
    {title: "Company", links: [{label: "About", href: "/about"}]}
  ].freeze

  # The contentinfo landmark — a real <footer>, not a styled <div>.
  def test_renders_a_footer_landmark
    render_inline(UI::FooterComponent.new(copyright: "© 2026 Acme"))

    assert_selector "footer"
  end

  # Link groups are real lists, and each link is a real <a> with an accessible name + href.
  def test_link_columns_are_semantic_lists
    render_inline(UI::FooterComponent.new(columns: COLUMNS))

    assert_selector "footer h3", text: "Product"
    assert_selector "footer ul li a[href='/features']", text: "Features"
  end

  # Every link carries the focus-ring utility (visible AAA focus outline), never focus:ring-*.
  def test_links_use_the_focus_ring_utility
    render_inline(UI::FooterComponent.new(columns: COLUMNS))

    assert_selector "footer a.focus-ring", minimum: 3
    assert_no_selector "footer a[class*='focus:ring-']"
  end

  # AAA semantic tokens (the design-token guarantee), not raw Tailwind. text-text-muted
  # resolves to the same neutral as text-text-body here, so it clears AAA 7:1.
  def test_renders_with_aaa_tokens
    render_inline(UI::FooterComponent.new(copyright: "© 2026 Acme"))

    assert_selector "footer.bg-surface-raised"
    assert_selector "footer p.text-text-muted", text: "© 2026 Acme"
  end

  # Column count maps to a STATIC grid-cols class (no interpolated phantom class).
  def test_column_count_maps_to_static_grid_class
    render_inline(UI::FooterComponent.new(columns: COLUMNS))

    assert_selector "footer div.md\\:grid-cols-2"
  end

  # The landmark is named only when label: is supplied (single footer needs no name).
  def test_landmark_named_only_when_label_given
    render_inline(UI::FooterComponent.new(copyright: "© 2026 Acme", label: "Site footer"))

    assert_selector "footer[aria-label='Site footer']"
  end

  def test_landmark_unnamed_by_default
    render_inline(UI::FooterComponent.new(copyright: "© 2026 Acme"))

    assert_no_selector "footer[aria-label]"
  end

  def test_merges_caller_classes
    render_inline(UI::FooterComponent.new(copyright: "© 2026 Acme", class: "mt-12"))

    assert_selector "footer.mt-12"
  end
end
