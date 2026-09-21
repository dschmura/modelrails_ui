# Anchored panels: staying on screen

A panel that floats against the viewport — a popover, a menu, a tooltip, a date
picker — is placed with CSS anchor positioning: a `position-area` cell saying
where it sits relative to its trigger, and a `position-try-fallbacks` value
saying where it may move when it does not fit.

## The rule

**Every anchored panel whose width the component decides carries a ceiling
resolved against the viewport.**

```
max-w-[calc(100vw-2rem)]
```

or, when the panel already has a ceiling of its own, the two combined:

```
max-w-[min(20rem,calc(100vw-2rem))]
```

Never two `max-w-*` utilities on one element. Two `max-width` declarations are
a cascade race decided by source order, not a smaller-wins — which is the
opposite of what the author means.

## Why a fallback is not enough

`position-try-fallbacks` moves a panel that does not fit. It cannot help a
panel that is wider than the screen, because flipping needs room on the other
side and there is none. A panel 420px wide on a 390px viewport overflows in
every fallback position, so the only thing that keeps it on screen is a
ceiling.

This is the half of #211 that survived measurement. The other half — adding an
inline-axis fallback to the block-axis placements — was dropped: the failure it
was filed for turned out to be a fixed-width panel that fits the viewport with
room to spare, and no measurement has yet shown a panel that flipping would
save.

## The exemption

A panel sized by its own trigger is already bounded by it:

```
[width:anchor-size(width)]
```

`combobox` and `mega_menu` size their panels this way. Capping them would make
the panel *narrower than the trigger it exists to line up with* in a full-bleed
layout — a visible misalignment traded for an overflow the sizing already
prevents. They are deliberately exempt.

## Enforcement

`test/test_anchored_panel_viewport_cap.rb` derives the set from the placement
machinery rather than a named list: any template declaring
`position-try-fallbacks` must either be anchor-sized or carry a viewport-bound
ceiling. A new anchored component fails that gate rather than quietly shipping
an unbounded panel.

What the gate proves is that the class ships. It cannot prove geometry — the
gem's browser lane serves no compiled stylesheet, so a bounding-box measurement
belongs in a host app, against real CSS.
