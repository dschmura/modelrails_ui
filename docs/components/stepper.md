# Stepper

Multi-step progress indicator with horizontal or vertical orientation. It communicates
*where you are* in a multi-step flow — it is NOT interactive navigation (the steps are not
links/buttons).

## Installation

```bash
rails g modelrails_ui:add stepper
```

Creates `app/components/ui/stepper_component.rb`.

## Usage

Each step requires a `status:` of `:complete`, `:current`, or `:pending`.

```erb
<%= ui :stepper, steps: [
  { label: "Account",  status: :complete },
  { label: "Profile",  status: :current },
  { label: "Billing",  status: :pending },
  { label: "Confirm",  status: :pending }
] %>
```

## Vertical orientation

```erb
<%= ui :stepper, orientation: :vertical, steps: [
  { label: "Order placed",    status: :complete,
    description: "Jan 12 at 09:00" },
  { label: "Processing",      status: :current,
    description: "Estimated 1–2 business days" },
  { label: "Shipped",         status: :pending },
  { label: "Delivered",       status: :pending }
] %>
```

## Step statuses

| Status | Appearance |
|--------|------------|
| `:complete` | Filled circle with a check mark |
| `:current` | Outlined circle with a filled dot; `aria-current="step"` |
| `:pending` | Outlined circle, muted colour |

## API

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `steps` | Array | required | Array of step hashes — see table below |
| `orientation` | Symbol | `:horizontal` | `:horizontal` or `:vertical` |
| `**html_attrs` | Hash | — | Forwarded to the `<ol>` element |

### Step hash

| Key | Type | Required | Description |
|-----|------|----------|-------------|
| `label` | String | Yes | Step name |
| `status` | Symbol | Yes | `:complete`, `:current`, or `:pending` |
| `description` | String | No | Supporting text (vertical orientation only) |

## When to use

- Showing progress through a known, ordered sequence (checkout, onboarding,
  a wizard) where the count of steps is fixed and visible.

## When not to use

- Steps are clickable destinations — that is navigation; use links/tabs.
- Progress is a single continuous percentage — use `progress` instead.

## Accessibility contract

- **Guarantees:** an `<ol>` with an i18n `aria-label` ("Progress" by default,
  via the `modelrails_ui.stepper.progress` locale key) so the list announces
  its purpose. The current step carries `aria-current="step"`; complete and
  pending circles carry an i18n `aria-label` ("Completed" / "Pending") so the
  status is named, not conveyed by the decorative glyph alone. The check icon
  and the `●`/`○` glyphs are decorative — the check `<svg>` is
  `aria-hidden="true"` and the glyph spans carry their own accessible name.
  The `<ol>` carries an explicit `role="list"`: Tailwind's preflight sets
  `list-style: none`, and Safari/VoiceOver drop the implicit list role once the
  marker is gone — taking the item count and per-item set position with it. No
  axe rule covers this.
- **You supply:** a `label:` per step, and a `status:` of `:complete`,
  `:current`, or `:pending` (defaults to `:pending`).

## Modes

`orientation: :horizontal` (default) · `orientation: :vertical`.
