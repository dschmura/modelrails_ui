# Menu-Widgets Band — Design (dropdown_menu · context_menu · menubar)

**Status:** Approved design. The task-by-task implementation plan is produced
separately by `superpowers:writing-plans` (`…-plan.md`).

**Goal:** Harden the **menu pattern** components — `dropdown_menu`, `context_menu`,
`menubar` — to the 10-point DoD, implementing the full WAI-ARIA APG menu-button
contract (roles + roving-tabindex keyboard navigation) behind a new dedicated
`menu` Stimulus controller. `dropdown_menu` is the band exemplar.

**Scope (decomposition):** The original "menu-widgets" set had 5 components across
TWO incompatible a11y patterns. This band covers only the **menu pattern** (the 3
above). `command` (command palette) and `combobox` share a *text-input + listbox +
filtering* model (`role="combobox"`/`listbox`/`option`, `aria-activedescendant`,
live filtering) — a separate **listbox/filter band**, designed later.

## Why this band is not "formalize-only"

`dropdown_menu` today is old-popover-shaped and has the same class of defects the
floating band did, plus the heavier menu contract:

| Gap | Detail |
|---|---|
| Trigger | a non-focusable `<span>` with a click action (no Enter/Space, no `aria-haspopup`/`aria-expanded`) |
| Menu semantics | panel is a plain `div`; no `role="menu"`, items are not `role="menuitem"` |
| Keyboard | the thin `dropdown` controller does toggle + click-outside **only** — no arrow nav, type-ahead, Home/End, Escape, or focus management |
| Positioning | CSS `absolute` + `ALIGN`, not the band's anchor positioning |
| Controller | its own `dropdown` controller, duplicating the floating toggle |

## §1 — The a11y contract (WAI-ARIA APG menu button)

- **Trigger** → real `<button type="button">` with `aria-haspopup="menu"`,
  `aria-expanded` (controller-managed), `aria-controls="{menu_id}"`.
- **Menu** → `role="menu"` (`id`); **items** → `role="menuitem"` (+ future
  `menuitemcheckbox`/`menuitemradio`); separators → `role="separator"`; group
  labels via `aria-label`/a labelled group.
- **Keyboard — roving tabindex** (DOM focus moves through items; exactly one item
  is `tabindex="0"` at a time, the rest `tabindex="-1"` — the APG-standard for
  menus, more robust for screen readers than `aria-activedescendant`):
  - Trigger: Enter / Space / ↓ opens and focuses the first item; ↑ opens and
    focuses the last.
  - In menu: ↑/↓ move (wrapping), Home/End jump, **type-ahead** focuses the next
    item whose label starts with the typed character(s), Enter/Space activate,
    **Escape** closes + returns focus to the trigger, **Tab** closes.
  - `context_menu`: opens at the pointer on `contextmenu` (right-click), else
    identical menu semantics.
  - `menubar`: top-level items in a horizontal `role="menubar"`; ←/→ move between
    them; ↓ (or Enter) opens a submenu and focuses its first item; submenus are
    `role="menu"` reusing the same item semantics.

## §2 — The `menu` controller (dedicated; the approved architecture)

Positioning is pure CSS now (anchor positioning — no controller), so the controller
owns just **open/close** + the **menu keyboard model**. One cohesive `menu`
controller lives at `…/dropdown_menu/menu_controller.js` (dropdown_menu is the
exemplar/home, mirroring how `dialog/modal_controller.js` and
`popover/floating_controller.js` host their bands' shared controllers). `context_menu`
and `menubar` reuse it via `EXTRA_STIMULUS` (the proven sharing mechanism — never
copied).

Responsibilities: `open`/`close`/`toggle` (manage `hidden` + `aria-expanded` +
move focus into the menu / restore to trigger); roving-focus navigation
(`next`/`prev`/`first`/`last` over `[role=menuitem]` targets, wrapping); type-ahead
(buffer keystrokes, match item text); `activate` (Enter/Space → click the item +
close); Escape/Tab/outside-click close. `context_menu` adds an `openAt(event)`
that positions at the pointer; `menubar` adds horizontal ←/→ across top-level items
and submenu open/close.

It does NOT reuse `floating` — menus are a distinct interaction (item navigation is
the bulk), and `floating` is already multi-modal (popover/tooltip/hover_card); a
4th heavy mode would bloat it.

## §3 — Positioning

- **dropdown_menu** → CSS anchor positioning (`position-area` + `position-try-fallbacks`,
  `fixed`, with the `absolute` fallback), same as tooltip/hover_card; placements via
  `side`/edge (+ corners later). Tethered with inline `anchor-name`/`position-anchor`.
- **context_menu** → positioned at the **pointer coordinates** on right-click.
  Anchor positioning can't anchor to a point, so this one keeps a small JS step in
  the controller (`openAt` sets fixed `top`/`left` from the event), then the menu
  semantics are identical.
- **menubar** → submenus anchor-position to their parent menubar item.

## §4 — Components & sequencing

`dropdown_menu` (exemplar) → `context_menu` → `menubar`.

| Component | Adds over the exemplar |
|---|---|
| `dropdown_menu` | the `menu` controller + the full APG menu contract; button trigger; anchor positioning |
| `context_menu` | pointer-triggered `openAt`; otherwise reuses the menu controller + item semantics |
| `menubar` | horizontal `role="menubar"` + ←/→; submenu open/close; has a `menubar_menu` sub-component |

`menubar` is the most complex (multi-file, submenus) — a Wave-4-sized unit; it's
sequenced last so the menu controller + item semantics are proven on the two
simpler components first.

## The 10-point DoD (each component) + menu specifics

renders · AAA semantic tokens only · correct ARIA (`role=menu/menuitem`, the
trigger contract above) · fail-loud guard on enums (e.g. `side`/`align`) · focus
management + 44px targets · disabled/invalid item states · i18n · doc-comment ·
slot API (trigger + items/content) · template-backed preview + `@param` playground.
Plus: **0a** render test (asserts the static role/tabindex scaffolding) + **0b**
browser-axe spec that drives the keyboard (open via Enter, ↓ navigates, type-ahead,
Escape closes + focus returns) and proves AAA on the open menu in both themes. The
render harness can't exercise JS, so the roving-focus/keyboard behavior is proven in
the app 0b (per `dialog`/`popover` precedent).

## Hardening artifacts & toolchain

Same groove: one gem PR per component-or-small-batch into `modelrails/harden`; app
adoption PR with the 0b proof; ledger rows + docs. **Gem:** `mise.toml` untrusted —
prefix Ruby cmds `PATH="…/ruby/4.0.5/bin:$PATH" bundle exec …`. **App:**
`mise exec -- bundle exec rspec …`.

## Risks & notes

- **Roving tabindex is the meat** — getting first/last focus, wrapping, type-ahead,
  and focus-restore right is the bulk of the work; it's behavioral, so the **app 0b
  keyboard spec is the real gate** (render tests only assert the static scaffolding).
- **context_menu pointer positioning** is the one spot that keeps JS positioning
  (anchor positioning can't tether to a point) — a small, contained `openAt`.
- **menubar** is genuinely big (submenus + a sub-component); treat it as its own
  wave, not a quick follow.
- **`menu` is a 4th controller** in the floating/menu surface (alongside `modal`,
  `floating`); deliberate — menu nav doesn't belong in `floating`.
- The old `dropdown` controller is deleted (superseded by `menu`), like
  `popover_controller.js` was by `floating`.
