# frozen_string_literal: true

require "render_test_helper"
load_component "chart", "chart_component.rb.tt"

# STRUCTURE-only render specs. A <canvas> is an opaque bitmap, so the chart's
# accessibility lives entirely in the DOM scaffolding asserted here: the canvas is
# a labelled graphic (role="img" + aria-label), and a visually-hidden data <table>
# carries the actual numbers (the WAI/APG complex-image text alternative). The app
# 0b axe spec proves AAA contrast of the rendered series in a real browser; here we
# assert the a11y contract + the fail-loud enum + semantic (not raw) tokens.
class ChartRenderTest < ViewComponent::TestCase
  def render_basic(**opts)
    defaults = {
      label: "Quarterly revenue",
      labels: %w[Jan Feb Mar],
      datasets: [
        {label: "Revenue", data: [100, 200, 150]},
        {label: "Costs", data: [80, 140, 110]}
      ]
    }
    render_inline(UI::ChartComponent.new(**defaults.merge(opts)))
  end

  def test_renders_a_canvas_wired_to_the_chart_controller
    render_basic

    assert_selector "canvas[data-controller='chart']", visible: :all
    assert_selector "canvas[data-chart-type-value='bar']", visible: :all
  end

  # The canvas is a single labelled graphic so AT announces *what the chart is*,
  # not an anonymous bitmap (a 1.1.1 non-text-content guarantee).
  def test_canvas_is_a_labelled_graphic
    render_basic

    assert_selector "canvas[role='img'][aria-label='Quarterly revenue']", visible: :all
  end

  # Absent an explicit label:, the accessible name falls back to the i18n default.
  def test_label_falls_back_to_i18n_default
    render_inline(UI::ChartComponent.new(labels: %w[A B], datasets: [{label: "X", data: [1, 2]}]))

    assert_selector "canvas[role='img'][aria-label='Chart']", visible: :all
  end

  # The text alternative: a visually-hidden data table wired to the canvas via
  # aria-describedby, carrying the real numbers a bitmap can't.
  def test_renders_a_visually_hidden_data_table_as_the_text_alternative
    render_basic

    assert_selector "table.sr-only", visible: :all
    assert_selector "table.sr-only caption", text: "Quarterly revenue", visible: :all
    # canvas points at the table id.
    table_id = page.find("table.sr-only", visible: :all)[:id]

    assert_selector "canvas[aria-describedby='#{table_id}']", visible: :all
  end

  # Series names become scoped column headers; category labels scoped row headers.
  def test_data_table_has_scoped_headers
    render_basic

    assert_selector "table.sr-only th[scope='col']", text: "Revenue", visible: :all
    assert_selector "table.sr-only th[scope='col']", text: "Costs", visible: :all
    assert_selector "table.sr-only th[scope='row']", text: "Jan", visible: :all
  end

  # Every data point lands in a cell.
  def test_data_table_renders_a_cell_per_data_point
    render_basic

    assert_selector "table.sr-only td", text: "100", visible: :all
    assert_selector "table.sr-only td", text: "110", visible: :all
  end

  # Fail loud: an unknown type raises rather than silently coercing to :bar.
  def test_unknown_type_raises
    assert_raises(ArgumentError) do
      render_inline(UI::ChartComponent.new(type: :bogus, datasets: []))
    end
  end

  # Every allowed type renders without raising and stamps the canvas value.
  def test_each_allowed_type_renders
    %w[bar line pie doughnut radar polarArea].each do |type|
      render_inline(UI::ChartComponent.new(type: type, labels: %w[A], datasets: [{label: "X", data: [1]}]))

      assert_selector "canvas[data-chart-type-value='#{type}']", visible: :all
    end
  end

  # Series with no explicit color get the AAA-tuned OKLCH palette — a semantic
  # value, never a raw hex. The config JSON rides in the data-chart-config-value.
  def test_default_series_uses_an_oklch_palette_not_raw_hex
    render_basic
    config = page.find("canvas", visible: :all)["data-chart-config-value"]

    assert_includes config, "oklch("
    refute_match(/#[0-9a-fA-F]{6}/, config)
  end

  # A caller-supplied per-series color is preserved (camelized, not overwritten).
  def test_caller_supplied_series_color_is_preserved
    render_inline(UI::ChartComponent.new(
      label: "X", labels: %w[A],
      datasets: [{label: "S", data: [1], background_color: "oklch(0.4 0.1 200)"}]
    ))
    config = page.find("canvas", visible: :all)["data-chart-config-value"]

    assert_includes config, "backgroundColor"
    assert_includes config, "oklch(0.4 0.1 200)"
  end

  # html_attrs pass through onto the canvas, alongside the a11y contract.
  def test_passes_through_html_attrs_onto_the_canvas
    render_inline(UI::ChartComponent.new(
      label: "X", id: "sales-chart", height: "240",
      labels: %w[A], datasets: [{label: "S", data: [1]}]
    ))

    assert_selector "canvas#sales-chart[height='240'][role='img']", visible: :all
  end

  # A caller can't clobber the graphic's role or accessible name.
  def test_caller_cannot_override_the_a11y_role
    render_inline(UI::ChartComponent.new(
      label: "Real label", role: "presentation", "aria-label": "spoofed",
      labels: %w[A], datasets: [{label: "S", data: [1]}]
    ))

    assert_selector "canvas[role='img'][aria-label='Real label']", visible: :all
    assert_no_selector "canvas[role='presentation']", visible: :all
  end

  # A caller-supplied class merges onto the wrapper without clobbering the base.
  def test_merges_caller_class_onto_the_wrapper
    render_basic(class: "mt-4")

    assert_selector "div.mt-4.relative", visible: :all
  end
end
