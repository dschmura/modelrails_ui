# Timeline

Vertical list of dated events with coloured dot indicators. Rendered as a semantic ordered list because the order is meaningful.

## Installation

```bash
rails g modelrails_ui:add timeline
```

Creates `app/components/ui/timeline_component.rb`.

## Usage

```erb
<%= ui :timeline do |t| %>
  <% t.with_item(date: "Jan 2025",  title: "Project kickoff") %>
  <% t.with_item(date: "Feb 2025",  title: "Alpha release",
                 description: "Core features complete.", variant: :success) %>
  <% t.with_item(date: "Mar 2025",  title: "Performance issue found",
                 variant: :danger) %>
  <% t.with_item(date: "Apr 2025",  title: "v1.0 shipped", variant: :success) %>
<% end %>
```

## Item variants

| Variant | Dot colour |
|---------|-----------|
| `:default` | Primary |
| `:info` | Blue |
| `:success` | Green |
| `:warning` | Amber |
| `:danger` | Red |
| `:muted` | Muted foreground |

`:destructive` is a deprecated, non-breaking alias for `:danger`.

## Rich item content

Add any HTML via a block after the named options:

```erb
<% t.with_item(date: "May 2025", title: "Conference") do %>
  <p class="text-sm text-muted-foreground mt-1">
    Presented at <%= link_to "RailsConf", "https://railsconf.com" %>.
  </p>
<% end %>
```

## API

### TimelineComponent

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `**html_attrs` | Hash | — | Forwarded to the `<ol>` element |

### ItemComponent (via `with_item`)

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `title` | String | required | Event label |
| `date` | String | `nil` | Date or time string shown above the title |
| `datetime` | String | `nil` | Machine-readable value for the `<time datetime>` attribute |
| `description` | String | `nil` | Supporting text shown below the title |
| `variant` | Symbol | `:default` | Dot colour — see Variants table |
| `**html_attrs` | Hash | — | Forwarded to the `<li>` element |

## When to use

- Showing an activity feed, audit trail, release history, or any dated
  sequence where the order carries meaning.

## When not to use

- The order is arbitrary (a set of unrelated rows) — use a `list_group`.
- You're building non-semantic `<div>` steps with a hand-drawn line; that
  loses the list/sequence semantics for assistive tech (see the Don't below).

## Accessibility contract

- **Guarantees:** a real `<ol>` of `<li>` (the sequence is announced as an
  ordered list); the connector line and marker dots are decorative
  (`aria-hidden`); event times are perceivable text, emitted as `<time>` with
  an optional machine-readable `datetime`; AAA-contrast tokens throughout; a
  valid item `variant` is required — an unknown one raises in development.
- **You supply:** the event `title:` (and optional `date:`/`datetime:`,
  `description:`, or block body) per item; titles are plain text, so the
  surrounding heading outline stays yours to control.

```
t.with_item(date: "Feb 2025", datetime: "2025-02", title: "Milestone reached",
            description: "Foundation phase complete", variant: :success)
```
