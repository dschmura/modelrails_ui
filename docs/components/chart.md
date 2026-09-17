# Chart

Canvas-based chart powered by Chart.js. Renders bar, line, pie, doughnut, radar, and polar area charts.

Requires `chart_controller.js` (copied automatically by the generator) and the Chart.js library in your importmap.

## Setup

Add Chart.js to your importmap before using this component:

```ruby
# config/importmap.rb
pin "chart.js", to: "https://cdn.jsdelivr.net/npm/chart.js@4/+esm"
```

## Installation

```bash
rails g modelrails_ui:add chart
```

Creates:
- `app/components/ui/chart_component.rb`
- `app/javascript/controllers/chart_controller.js`

## Usage

```erb
<%= ui :chart,
       type: :bar,
       labels: ["Jan", "Feb", "Mar", "Apr", "May"],
       datasets: [
         { label: "Revenue", data: [120, 190, 80, 210, 150] }
       ] %>
```

```ruby
ui :chart, type: :bar, label: "Quarterly revenue vs. costs",
  labels: ["Jan", "Feb", "Mar"],
  datasets: [
    { label: "Revenue", data: [100, 200, 150] },
    { label: "Costs",   data: [80,  140, 110] }
  ]
```

## Chart types

| Type | Description |
|------|-------------|
| `:bar` | Vertical bar chart (default) |
| `:line` | Line chart |
| `:pie` | Pie chart |
| `:doughnut` | Doughnut chart |
| `:radar` | Radar/spider chart |
| `:polarArea` | Polar area chart |

## Multiple datasets

```erb
<%= ui :chart,
       type: :line,
       labels: ["Q1", "Q2", "Q3", "Q4"],
       datasets: [
         { label: "2024", data: [100, 140, 130, 180] },
         { label: "2025", data: [110, 160, 150, 200],
           background_color: "#3b82f6", border_color: "#3b82f6" }
       ] %>
```

Dataset keys use snake_case and are automatically camelized for Chart.js (e.g. `background_color:` becomes `backgroundColor`).

## Chart.js options

Pass any Chart.js `options` hash to override defaults:

```erb
<%= ui :chart,
       type: :bar,
       labels: ["A", "B", "C"],
       datasets: [{ label: "Score", data: [70, 85, 90] }],
       options: { responsive: false, plugins: { legend: { display: false } } } %>
```

## API

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `type` | Symbol | `:bar` | Chart type — see Chart types table. An unknown type FAILS LOUD (raises `ArgumentError`) — no silent fallback |
| `labels` | Array | `[]` | X-axis or category labels |
| `datasets` | Array | `[]` | Array of dataset hashes (snake_case keys are camelized) |
| `options` | Hash | `{}` | Merged into the Chart.js `options` object |
| `label` | String | `nil` | One-line summary of what the chart shows (REQUIRED for AT — see the accessibility contract). Falls back to an i18n default |
| `**html_attrs` | Hash | — | Forwarded to the `<canvas>` element |

## Accessibility contract

A `<canvas>` is an opaque bitmap — pixels carry no semantics, so a chart drawn
to it is invisible to assistive tech (a WCAG 1.1.1 non-text-content failure).
We give AT TWO things, mirroring the WAI/APG "complex image" pattern:

- **Guarantees:**
  1. The canvas is a labelled graphic: `role="img"` + an `aria-label` summary
     (from `label:`, i18n-defaulted) so AT announces *what the chart is*, not an
     anonymous canvas. The component owns this — a caller can't clobber it.
  2. A **visually-hidden data table** (`.sr-only`) renders the same numbers as
     a real `<table>` (caption + `<th scope>` row/column headers), wired to the
     canvas via `aria-describedby`. Screen-reader users get the actual data, not
     just the summary — the textual equivalent the bitmap can't provide.
  - Decorative SVG/canvas chrome is `aria-hidden`; the only AT-visible content
    is the label + the table.
- **You supply:** a meaningful `label:` and well-formed `datasets:` (each with a
  `label:` so the table columns are named). Color is optional — the palette is
  AAA-tuned by default; if you override, keep series ≥3:1 against the surface
  (WCAG 1.4.11, graphics) and don't rely on color alone to distinguish series.
