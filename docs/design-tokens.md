# Design tokens: surfaces

> Scope: this page states the **surface** rules, which components must follow.
> `customization.md` also lists a token table; that table is stale and is being
> rewritten under issue #193. Where the two disagree, this page is correct.

## The four surfaces

| Token | What it is | Light | Dark |
|---|---|---|---|
| `bg-surface` | **The page.** The ground everything else sits on. | `neutral-50` | `neutral-900` |
| `bg-surface-raised` | A container that sits **on** the page — cards, lists, tables. | white | `neutral-800` |
| `bg-surface-overlay` | A container that floats **above** the page — dialog, popover, sheet, menus. | white | `neutral-800` |
| `bg-surface-sunken` | A well **inside** a container — table headers, code blocks, hover fills. | `neutral-100` | `neutral-950` |

`raised` and `overlay` resolve to the same value today. They are kept distinct
because they answer different questions, and a future elevation change (a shadow,
a border treatment, a translucent overlay) will want to move one without the other.

## The rule for a bordered container

A component that renders a bordered box picks **one** of two surfaces:

- **`bg-surface-raised`** if it sits on the page.
- **`bg-surface-overlay`** if it floats above it.

**Never `bg-surface`.** That is the page colour, so a container painted with it is
the same shade as the ground beneath it and reads as a bare border — and whether
that looks deliberate depends entirely on what background the host app sets.

**Never `bg-surface-sunken`** for the container itself. A well belongs inside a
container, not around one.

This is enforced, not just documented: `test/test_container_surface.rb` scores every
template that paints a bordered box and fails on a wrong choice, so a new component
cannot quietly introduce a third answer.

## What the host page should be

The rule assumes the page is `bg-surface`. A host whose `<body>` is
`bg-surface-raised` has painted the page the same colour as its cards, and every
card-shaped container in the app flattens into the background.

```erb
<body class="bg-surface text-text-body">
```

## History

The library briefly held three answers at once — `card` on `bg-surface-raised`,
`list_group` and `table` on `bg-surface`, and `data_table` with no surface at all —
so a list and a table side by side read as different kinds of object. Resolved in
issue #210 in favour of `bg-surface-raised`, which eight other components were
already using.
