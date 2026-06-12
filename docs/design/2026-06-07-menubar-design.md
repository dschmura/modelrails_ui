# Menubar — Design (menu band #3, final)

**Status:** Approved design (Option A, panel-validated). The task-by-task implementation
plan is produced separately by `superpowers:writing-plans` (`…-plan.md`).

**Goal:** Harden `menubar` (+ its `menubar_menu` sub-component) to the WAI-ARIA APG
**menubar** pattern — a horizontal `role="menubar"` of top-level items, each opening a
vertical submenu that behaves exactly like a `dropdown_menu`. Reuse the proven shared
`menu` Stimulus controller for the submenus; add a thin new `menubar` controller for the
horizontal coordination layer.

**Scope cut:** **single-level submenus only** (menubar → one submenu level). Deeply-nested
sub-submenus (a submenu item that itself opens a sub-submenu) are APG-permitted but a large
complexity multiplier most app menubars don't need — **deferred** to a future pass.

**Band context:** 3rd/final component of the menu band (after `dropdown_menu` and
`context_menu`, both SHIPPED & PROVEN). Same groove (0a render test + app 0b browser-axe
AAA + ledger + doc). Toolchain: gem `PATH="…/ruby/4.0.5/bin:$PATH" bundle exec …` (render
load path `-Itest/render`); app `mise exec -- bundle exec …`.

## §0 — Why this band is not "formalize-only"

The current `menubar` is a thin click/hover bar: `MenubarComponent` (`renders_many :menus`,
a `flex` bar, no `role`) + `MenubarMenuComponent` (a `<button>` + a hidden `absolute`
submenu) + a `menubar_controller.js` that does click-toggle + hover-follow + close-all —
**no `role=menubar`, no roving tabindex, no keyboard nav, no aria-haspopup/expanded, no
submenu item semantics.** Hardening adds the full APG keyboard + ARIA contract.

## §1 — Architecture (Option A — panel-validated, unanimous)

A menubar is **two interaction levels**, decomposed onto two controllers:

- **Each `menubar_menu` submenu IS a `menu` controller instance** (reused via
  `EXTRA_STIMULUS`, exactly like `dropdown_menu`/`context_menu`). The bar-item button is
  the menu's **`trigger`**; the submenu panel is the **`menu`**; submenu items are
  **`menuitem`**s. The `menu` controller already provides everything a submenu needs:
  open/close + `aria-expanded` sync on the bar item, vertical roving tabindex (↑/↓ wrap,
  skip `aria-disabled`), Home/End, type-ahead, Enter/Space activate, **Escape closes the
  submenu and restores focus to the bar item**, Tab closes. **The `menu` controller needs
  NO additions for menubar** (unlike `context_menu`, which added `openAt`).

- **A new thin `menubar` controller** (rewrite of the current one) owns ONLY the horizontal
  layer: roving tabindex across the bar items (the menubar is **one** tab stop), and a
  bar-level `keydown` handler for `←/→`/Home/End/type-ahead and submenu coordination. It
  references the submenu `menu` controllers via **Stimulus outlets** (`static outlets =
  ["menu"]` → `this.menuOutlets`), and drives them with `menuOutlets[i].open({focus})` /
  `.close()`, reading state via `menuOutlets[i].openValue`.

`EXTRA_STIMULUS`: add `"menubar_menu" => {source: "dropdown_menu/menu_controller.js", name:
"menu"}`. The `menubar` controller stays colocated at `menubar/menubar_controller.js`
(rewritten). The old thin `menubar_controller.js` is replaced.

## §2 — The implicit key-routing (the crux)

Keys route by **focus location + `preventDefault`**, no mode flag:

- **`menubar#navigate` (bound `keydown->menubar#navigate` on the bar) starts with
  `if (event.defaultPrevented) return`.** Any key the inner `menu` controller already
  claimed (it `preventDefault`s arrows/Home/End/Escape/Tab) is skipped here.
- **`←/→` are NEVER claimed by `menu`** (`menu#navigate` has no `ArrowLeft`/`ArrowRight`
  case, no `preventDefault`), so they bubble to `menubar#navigate`:
  - bar item focused, no submenu open → move roving focus to the adjacent bar item (wrap).
  - submenu open / submenu item focused → **close the current submenu, move to the adjacent
    bar item, open ITS submenu, focus its first item** (the menubar "follow"). Driven via
    `menuOutlets` (`.close()` the current, `.open({focus:"first"})` the adjacent).
- **`↓`/Enter/Space/`↑` on a focused bar-item button** are handled by the reused
  `menu#triggerKeydown` (opens that item's submenu, focus first / last) — `preventDefault`'d,
  so `menubar#navigate` skips them via `defaultPrevented`.
- **Home/End**: on a bar item (no submenu) → unclaimed → `menubar#navigate` jumps to the
  first/last bar item. Inside a submenu → claimed by `menu#navigate` → skipped here.
- **Type-ahead — the one explicit guard:** the `menu` controller runs type-ahead WITHOUT
  `preventDefault`, so a letter typed in an open submenu bubbles to the bar. To avoid
  double-matching, **`menubar#navigate` suppresses bar-level type-ahead while any submenu is
  open** (`if (this.menuOutlets.some(o => o.openValue)) return` before bar type-ahead). Bar
  type-ahead only runs when no submenu is open.

> **STANDING INVARIANT (comment it):** never add an `ArrowLeft`/`ArrowRight` case to
> `menu#navigate` — the menubar relies on `←/→` bubbling unclaimed. A top comment on
> `menubar_controller.js` documents the coordinator role + this invariant.

## §3 — The a11y contract (WAI-ARIA APG menubar)

- **Bar** → `role="menubar"` (+ accessible name via `aria-label`, e.g. "Main"); contains the
  bar items in a horizontal row.
- **Bar item** (the `menubar_menu` trigger button) → `role="menuitem"`,
  `aria-haspopup="menu"`, `aria-expanded` (synced by the reused `menu` controller),
  `aria-controls="{submenu_id}"`; **roving tabindex** (exactly one bar item `tabindex="0"`,
  rest `-1`, managed by `menubar`); disabled bar items `aria-disabled` + skipped; a visible
  **`:focus-visible`** treatment (not `:focus`).
- **Submenu** → `role="menu"` (`id`), `aria-labelledby` the bar item; items → `role="menuitem"`
  with roving tabindex — the **same `ITEM`/`SEPARATOR` model as `dropdown_menu`** (focus-visible
  highlight + `aria-disabled` treatment; disabled/separator/href variants; caller-attr-safe
  item slot).
- **Keyboard map** (by focus location, per §2): Tab into the menubar → one bar item; `←/→`
  move (wrap); Home/End jump; type-ahead at the bar (when closed); `↓`/Enter/Space opens the
  submenu + focuses first; `↑` opens + focuses last. In a submenu: `↑/↓` (wrap, skip disabled),
  Home/End, type-ahead, Enter/Space activate, Escape → close + focus the bar item, `←/→` →
  close + switch to the adjacent bar item's submenu, Tab → close + leave the menubar.

## §4 — Positioning

Submenus use **CSS anchor positioning** (reuse `dropdown_menu`'s approach): the submenu panel
is `fixed`, tethered to its bar item via inline `anchor-name`/`position-anchor`, placed
`bottom_start` (below the bar item, start-aligned) with `position-try-fallbacks: flip-block`
for viewport-overflow safety (a bar near the right edge → its submenu stays on-screen), and
the `absolute bottom-full`-style fallback for pre-Baseline browsers. Replaces the current
`absolute left-0 top-full` (a right-edge overflow liability). Use `dropdown_menu`'s
`bottom_start` placement string (single placement — menubar submenus always open below,
start-aligned).

## §5 — Components & file structure

| File | Responsibility | Action |
|---|---|---|
| `…/menubar/menubar_controller.js` | The thin `menubar` coordinator (roving + `←/→`/Home/End/type-ahead + outlet coordination) | Rewrite |
| `…/menubar/menubar_component.rb.tt` | `role=menubar` bar; `renders_many :menus`; `BAR` class; `aria-label`; `data-controller=menubar` + `keydown->menubar#navigate` + outlet selector | Rewrite |
| `…/menubar/menubar_menu_component.rb.tt` | A `menu`-controller submenu: bar-item button (`role=menuitem`, aria-haspopup/expanded/controls, `data-menu-target=trigger` + `data-menubar-target=item` + `menu#triggerKeydown`) + `role=menu` `fixed` anchor-positioned panel (`data-menu-target=menu` + `menu#navigate`) + `with_item` slots (dropdown_menu's item model) | Rewrite |
| `lib/generators/modelrails_ui/components.rb` | `EXTRA_STIMULUS`: add `menubar_menu → menu` | Modify |
| `test/render/menubar_render_test.rb` | 0a structure-only (roles, roving tabindex, aria, the menu+menubar wiring, outlet selector) | Create |
| `test/test_generator_components.rb` | `test_menubar_*` assertions (menubar has its own controller; menubar_menu uses EXTRA_STIMULUS → menu) | Modify |
| `docs/components/menubar.md` | Usage doc | Create/Rewrite |
| `COMPONENT_STATUS.md` | Two ledger rows (menubar, menubar_menu) → `hardened` then `proven` | Modify |

**Wiring detail:** each `menubar_menu` root element is the `menu` controller (`data-controller=menu`)
AND carries a marker (e.g. `data-menubar-item` attr) matched by the menubar's
`data-menubar-menu-outlet="[data-menubar-item]"`. The bar-item button inside it is BOTH
`data-menu-target=trigger` (for the reused menu controller) and `data-menubar-target=item`
(for the menubar's roving). `itemTargets[i]` (bar buttons) and `menuOutlets[i]` (submenu
controllers) align by DOM order (one of each per `menubar_menu`).

## §6 — DoD + verification

Per component (menubar + menubar_menu): renders · AAA semantic tokens only · correct ARIA
(role=menubar/menuitem/menu, the trigger/roving/aria-haspopup contract) · fail-loud guard
where applicable · focus management + 44px targets + focus-visible · disabled bar/submenu
items · i18n (the bar `aria-label`; item text is author-supplied) · doc-comment · slot API
(menus / items) · template-backed preview. Plus **0a** render test (the two-level static
scaffolding: roving tabindex, roles, the `menu` + `menubar` target/outlet wiring) + **0b**
browser spec — **the real gate** — driving the FULL menubar keyboard (Tab-in → one item;
`←/→` wrap; `↓`/Enter opens submenu + first; `↑` opens + last; **`←/→`-from-open-submenu
closes + switches + opens** the adjacent; Escape → bar item; Home/End; type-ahead at both
levels without double-match; activate) and proving AAA on the open menubar+submenu in both
themes. The render harness can't exercise JS or the outlet coordination, so all behavior is
proven in the app 0b (per `dropdown_menu`/`context_menu` precedent).

## §7 — Risks & notes

- **The outlet coordination + two-level routing is the meat** — the `←/→`-from-submenu
  follow (close + switch + open via outlets) and the `defaultPrevented`/type-ahead-guard
  routing are the highest-risk behaviors; the **app 0b is the real gate** (render tests only
  assert static scaffolding). Test the `←`-from-submenu contract end-to-end explicitly.
- **Outlet timing:** the `menubar` controller should defensively tolerate outlets connecting
  after itself (guard `this.hasMenuOutlet`/`menuOutlets.length`); Stimulus connects child
  controllers and registers outlets asynchronously.
- **Type-ahead double-match** (§2): bar type-ahead MUST be suppressed while a submenu is open.
  (Alternative considered: make `menu`'s type-ahead `preventDefault` matched letters — a
  cleaner shared-controller change but it would require re-proving dropdown_menu +
  context_menu 0b; default to the menubar-side guard to keep `menu` frozen, unless the plan
  finds the shared change warranted.)
- **`menu` controller stays frozen** — menubar adds NO methods to it (pure reuse). If the 0b
  reveals a genuine shared-controller need, it's a deliberate change with both siblings'
  0b re-proven.
- **Single-level submenus only** (scope cut) — no `aria-haspopup` on submenu items, no nested
  sub-submenus; deferred.
- **menubar is a wave-sized unit** — two components, two-level interaction, outlet
  coordination; its own gem PR + app PR.
- The old thin `menubar_controller.js` (click/hover-follow) is fully replaced by the
  keyboard-first coordinator; hover-to-open MAY be retained as a convenience action but is
  not part of the APG keyboard contract.
