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
- **Accessible name** → the trigger MUST have an accessible name: visible text
  content OR an `aria-label`. Icon-only triggers (hamburger, ⋮) MUST pass
  `aria-label`. The component **fails loud** when a trigger has neither (same guard
  ethos as the enum guards) — a nameless menu button is unusable by AT.
- **Menu** → `role="menu"` (`id`); **items** → `role="menuitem"` (+ future
  `menuitemcheckbox`/`menuitemradio`); separators → `role="separator"`; grouped
  items sit in `<div role="group" aria-labelledby="{label_id}">` with a labelled
  heading (the APG group pattern), not a bare divider.
- **Disabled items** → `aria-disabled="true"`, kept in the DOM (never removed);
  arrow-nav and type-ahead **skip** them and activation **rejects** them. They get
  a non-interactive treatment on semantic tokens (reduced emphasis +
  `cursor-not-allowed`), never a raw-palette gray.
- **Keyboard — roving tabindex** (DOM focus moves through items; exactly one item
  is `tabindex="0"` at a time, the rest `tabindex="-1"` — the APG standard for
  menus, more robust for screen readers than `aria-activedescendant`):
  - Trigger: Enter / Space / ↓ opens and focuses the **first** enabled item; ↑
    opens and focuses the **last**.
  - In menu: ↑/↓ move (wrapping, skipping disabled), Home/End jump to the
    first/last enabled item, Enter/Space **activate**, **Escape** closes + returns
    focus to the trigger, **Tab** closes the menu *and* advances focus to the next
    element in page order.
  - **Activation is input-agnostic** — Enter, Space, OR a left-click / pointerup on
    a `[role=menuitem]` all activate the item and close the menu.
  - **Type-ahead** — buffers keystrokes and focuses the next enabled item whose
    label starts with the buffer (case-insensitive, leading whitespace trimmed).
    The buffer resets after **1s** idle; a no-match keystroke is ignored and the
    buffer preserved. Matching begins at the item after current focus and wraps.
  - **Focus edges** — opening moves focus into the menu (first/last per above);
    closing for any reason (Escape, outside-click, selection) restores focus to the
    trigger — *except* Tab, which closes then advances to the next page element.
  - `context_menu`: opens at the pointer on `contextmenu` (right-click) **and** on
    **Shift+F10** / the ContextMenu key while the host has focus (positioned near
    the focused element). Keyboard parity is mandatory (WCAG 2.1.1 — right-click is
    pointer-only); thereafter identical menu semantics.
  - `menubar`: top-level items in a horizontal `role="menubar"`; ←/→ move between
    them (wrapping); ↓ (or Enter) opens a submenu and focuses its first item, ↑ its
    last; Escape closes the submenu back to its menubar item; submenus are
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
(`next`/`prev`/`first`/`last` over **enabled** `[role=menuitem]` targets, wrapping,
skipping `aria-disabled`); type-ahead (buffer keystrokes with a 1s reset, match
item text case-insensitively); `activate` (Enter / Space / left-click → activate
the item + close); Escape/Tab/outside-click close with focus restoration.
`context_menu` adds an `openAt(event)` that positions at the pointer (bound to both
`contextmenu` and Shift+F10); `menubar` adds horizontal ←/→ across top-level items
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
  semantics are identical. The **Shift+F10** open path has no pointer coordinates,
  so `openAt` falls back to the focused host element's bounding rect.
- **menubar** → submenus anchor-position to their parent menubar item.

> **Inherited dependency & CI scope:** the anchor-positioning approach — and its
> known limitation (the flip *clamps* on-screen rather than flipping to the
> opposite side, and cross-browser flip behavior is **not** exercised by the
> Chromium-only test runner) — comes from the floating band. See
> `2026-06-06-wave5-floating-overlays-design.md` § *Accepted limitation*.

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
trigger contract above, **accessible-name guard**) · fail-loud guard on **each
component's own enums** (`dropdown_menu`/`menubar` validate `side`; **`context_menu`
has none** — it is pointer/Shift+F10-positioned, so it carries no `side` prop) ·
focus management + 44px targets · disabled items via `aria-disabled` **plus a
visible `:focus-visible` ring on semantic tokens** (the roving item must show where
focus is — no `outline-none` without a replacement) · i18n · doc-comment · slot API
(trigger + items/content) · template-backed preview + `@param` playground.
Plus: **0a** render test (asserts the static role/tabindex scaffolding) + **0b**
browser-axe spec that **drives the full keyboard contract** — open via Enter and ↑
(first/last), ↓/↑ wrap **skipping disabled**, Home/End, type-ahead (incl. the 1s
buffer reset), pointer *and* keyboard activation, Escape/Tab/outside-click focus
restoration, and (context_menu) **Shift+F10** parity — and proves AAA on the open
menu in both themes. The render harness can't exercise JS, so all roving-focus /
keyboard behavior is proven in the app 0b (per `dialog`/`popover` precedent); axe
proves *structural* AAA only, so these behaviors exist **because the 0b drives
them**, not because CI would otherwise catch them.

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
  wave, not a quick follow. Open at that point: whether `menubar_menu` needs its
  own submenu controller or can ride the shared `menu` controller via
  `EXTRA_STIMULUS` (decide when the menubar wave starts, once `menu` is proven on
  the two simpler components).
- **`menu` is a 4th controller** in the floating/menu surface (alongside `modal`,
  `floating`); deliberate — menu nav doesn't belong in `floating`.
- The old `dropdown` controller is deleted **in the gem template** (superseded by
  `menu`), like `popover_controller.js` was by `floating`. **Correction (2026-06-07,
  post-exemplar):** this applies ONLY to the gem template's copy. The *host app's*
  same-named `dropdown_controller.js` is a distinct, app-owned controller that powers
  the hand-rolled user menu + workspace switcher (`shared/_user_menu*`,
  `shared/_settings_sidebar_switcher`) — it must NOT be deleted on adoption (doing so
  broke 25 specs; restored in app commit `9f8f93c`). Migrating those surfaces to the
  `menu` controller / `UI::DropdownMenuComponent` is a separate future effort.
