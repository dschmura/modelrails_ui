# Component Status

Tier ledger for the modelrails_ui hardening program (see
`docs/design/2026-06-03-component-hardening-program-design.md`). Keeps the library
honest mid-program: only `proven`/`hardened` components are safe to adopt downstream
without extra verification.

- **proven** — render test + real app browser-axe AAA proof (0a + 0b).
- **hardened** — meets the 10-point DoD with a render test (0a); app adoption in progress.
- **experimental** — structurally present but unverified. Adopt at your own risk.
- **broken** — known generation/runtime bug. Do not adopt.

| Component | Tier | Render test | App-adopted (axe) | Notes |
| --- | --- | --- | --- | --- |
| button | proven | ✅ | ✅ | SP1 exemplar |
| alert | proven | ✅ | ✅ | Wave 1 exemplar (gem #4 + app #222 merged) |
| select | proven | ✅ | ✅ | Wave 1 (native AAA select; id fallback; invalid/describedby) — app #223 merged |
| checkbox | proven | ✅ | ✅ | Wave 1 form-control pattern-setter — app #223 merged |
| radio_group | proven | ✅ | ✅ | Wave 1 (group aria-label; per-option ids; invalid on group) — app #223 |
| switch | proven | ✅ | ✅ | Wave 1 (aria-checked bug fixed; peer-sibling track; 44px) — app #223 |
| toggle | proven | ✅ | ✅ | Wave 1 (fail-loud size guard; 44px sizes; sm≈default nit deferred) — app #223 |
| badge | proven | ✅ | ✅ | Wave 1 (fail-loud guard; destructive dark-AAA fix; href polymorphism) — app #224 |
| data_table | proven | ✅ | ✅ | Wave 1 (kbd-sort + aria-sort; live region; 44px; i18n; sort-reorder bug fixed #7) — app #224 |
| input | proven | ✅ | ✅ | Wave 2 (full form-control API; SP2-adopted) — render test added |
| textarea | proven | ✅ | ✅ | Wave 2 (form-control API; SP2-adopted) — render test added |
| file_input | proven | ✅ | ✅ | Wave 2 (form-control API + a11y; SP2-adopted) — render test added |
| label | proven | ✅ | ✅ | Wave 2 (explicit AAA token; for-assoc; decorative required `*`) |
| search_input | proven | ✅ | ✅ | Wave 2 (form-control API; aria-label accessible name; 44px) |
| number_input | proven | ✅ | ✅ | Wave 2 (form-control API; id fallback; 44px; spinners hidden) |
| range | proven | ✅ | ✅ | Wave 2 (native slider; invalid/describedby; id fallback) |
| floating_label | proven | ✅ | ✅ | Wave 2 (sets aria-invalid/required/describedby; always-on id/for; peer float) |
| rating_input | proven | ✅ | ✅ | Wave 2 (semantic warning-icon token, was raw yellow-400; group aria-label; 44px stars; i18n) |
| form_field | proven | ✅ | ✅ | Convention pass B1 (gem #32 + app #255): repaired the broken standalone field — binds `<label for>`, hint/error ids, yields `input_attrs` (id+describedby+invalid+required) to the slotted control; data-slot adjacency spacing |
| kbd | proven | ✅ | ✅ | Wave 3 display-primitive exemplar (doc + 0a + template-backed preview + 0b). text-text-muted is AAA here (same neutral as body) — no contrast change |
| separator | proven | ✅ | ✅ | Wave 3 (aria-orientation only when semantic; role none/separator) |
| skeleton | proven | ✅ | ✅ | Wave 3 (aria-hidden decorative placeholder; motion-reduce:animate-none) |
| spinner | proven | ✅ | ✅ | Wave 3 (i18n sr-only loading text via t default; role=status; sizes) |
| progress | proven | ✅ | ✅ | Wave 3 (optional label: → aria-label accessible name; clamp; valuenow/min/max) |
| indicator | proven | ✅ | ✅ | Wave 3 (raw palette → semantic success/warning + text-on-interactive; fail-loud variant) |
| image | proven | ✅ | ✅ | Wave 3 (required alt; loading-mode validation; conditional srcset/sizes/width/height) |
| figure | proven | ✅ | ✅ | Wave 3 (figcaption only when caption given; text-text-muted is AAA here) |
| aspect_ratio | proven | ✅ | ✅ | Display-2 (presentational ratio wrapper; already clean — layout-only `overflow-hidden`, no enum so no fail-loud; slotted media carries its own a11y). 0a + app 0b/AAA CI green (#256) |
| card | proven | ✅ | ✅ | Display-2 (bare `border` → `border-border`; card_title hardcoded `<h3>` heading-hijack → caller-owned `level:` + fail-loud guard + `text-text-heading`). 0a + app 0b/AAA CI green (#256) |
| banner | proven | ✅ | ✅ | Display-2 (raw palette → tinted signal tokens; `role=region` + i18n aria-label; fail-loud variant; dismissible close button w/ focus-ring + co-located `banner_controller.js`). 0a + app 0b/AAA CI green (#256) |
| list_group | proven | ✅ | ✅ | Display-2 (invalid `<a>`-in-`<ul>` → `li>a`; added link focus-ring + aria-current=page on active; fail-loud variant). 0a + app 0b/AAA CI green (#256) |
| chat_bubble | proven | ✅ | ✅ | Display-2 (who-spoke by color/alignment alone → always-present sr-only direction label + optional author; received `text-text-heading`→`text-text-body`; fail-loud on non-boolean sent). 0a + app 0b/AAA CI green (#256) |
| footer | proven | ✅ | ✅ | Display-2 (`<footer>` contentinfo landmark; link columns are heading + `<ul>`/`<li>`/`<a>`; added the missing `focus-ring` on links; interpolated `md:grid-cols-#{n}` phantom class → static COLS map; optional i18n `label:` for multi-footer pages). 0a + app 0b/AAA CI green (#256) |
| avatar | proven | ✅ | ✅ | Display-1b (added fail-loud `coerce_size`; image alt / initials accessible-name / decorative aria-hidden; `bg-hue-initials`+white is the fixed AAA hue utility — correctly NOT "fixed"). 0a + app 0b/AAA CI green (#257) |
| iframe | proven | ✅ | ✅ | Display-1b (required non-blank `title:` accessible name; loading clamp). 0a + app 0b/AAA CI green (#257) |
| picture | proven | ✅ | ✅ | Display-1b (required base-img `alt`; `<source>` art-direction/format fallbacks; loading clamp — mirrors `image`). 0a + app 0b/AAA CI green (#257) |
| device_mockup | proven | ✅ | ✅ | Display-1b (raw palette `bg-white`/`bg-red-400`… → semantic tokens; decorative notch/browser-chrome aria-hidden; fail-loud phone/browser/tablet variant). 0a + app 0b/AAA CI green (#257) |
| map_area | proven | ✅ | ✅ | Display-1b (fail-loud alt-per-`<area href>` — was silent `alt=""`; img alt + usemap↔map-name match; legacy mechanism, documented). 0a + app 0b/AAA CI green (#257) |
| timeline | proven | ✅ | ✅ | Display-1b (raw `bg-green-500`/`amber-500` → semantic signal dots; `<ol>`/`<li>` order + decorative aria-hidden dots; `<time datetime>`; fail-loud + destructive alias). 0a + app 0b/AAA CI green (#257) |
| scroll_area | proven | ✅ | ✅ | Display-1b (WCAG 2.1.1: focusable region `tabindex=0`+`role=region`+mandatory name+`focus-ring`; `focusable:false` opt-out; fail-loud orientation + missing-name). 0a + app 0b/AAA CI green (#257) |
| dialog | proven | ✅ | ✅ | Wave 4 overlays exemplar (native <dialog>; 0a + JS-behavior 0b: open/escape/aria-modal + AAA on live modal). Was adopted unverified; now app-adopted + 0b green (#241) |
| alert_dialog | proven | ✅ | ✅ | native `<dialog role=alertdialog>` (Wave 4); shared `modal` controller; 0a render test + role/labelledby/describedby + 44px i18n close |
| drawer | proven | ✅ | ✅ | native bottom `<dialog>` slide-up (Wave 4); shared `modal` controller (translateY); decorative drag-handle + 44px close; 0a |
| sheet | proven | ✅ | ✅ | native side `<dialog>` per-side slide (Wave 4); fail-loud `coerce_side`; shared `modal` controller; 0a |
| popover | proven | ✅ | ✅ | Wave 5a floating exemplar (CSS positioning + shared `floating` controller; real button trigger w/ aria-haspopup/expanded/controls; role=dialog panel named by label:; Escape + outside-click close w/ focus return; fail-loud side/align). 0a render test |
| tooltip | proven | ✅ | ✅ | Wave 5b floating (shows on hover+focus; role=tooltip + aria-describedby; Escape-dismiss via shared `floating` controller w/ group-data-[dismissed]!; fail-loud side). 0a render test |
| hover_card | proven | ✅ | ✅ | Wave 5b floating (JS hover-intent open/close w/ close-delay so the pointer can cross to the card + click its content; Escape closes + returns focus to trigger; optional role=group label; fail-loud side). 0a render test |
| dropdown_menu | proven | ✅ | ✅ | Menu-band exemplar (Wave 6): APG menu-button via shared `menu` controller (roving tabindex, type-ahead, Escape/Tab/outside-click dismissal); CSS anchor positioning (side×align). 0a render test; app 0b green + AAA CI (#246) |
| context_menu | proven | ✅ | ✅ | Menu-band (Wave 6): right-click + Shift+F10 APG menu; reuses the shared `menu` controller via EXTRA_STIMULUS (+ openAt); focusable host trigger; JS pointer positioning (no side/align). 0a render test; app 0b green + AAA CI (#248) |
| menubar | proven | ✅ | ✅ | Menu-band (Wave 6) final: APG menubar (role=menubar, roving ←/→/Home/End/type-ahead) via a thin `menubar` coordinator + Stimulus outlets; single-level submenus. 0a render test; app 0b green + AAA CI (#249) |
| menubar_menu | proven | ✅ | ✅ | menubar sub-component: bar item (role=menuitem, aria-haspopup) + role=menu submenu reusing the shared `menu` controller via EXTRA_STIMULUS; CSS anchor positioning; dropdown_menu item model. Covered by the menubar 0a/0b (#249) |
| tabs | proven | ✅ | ✅ | Navigation band (Wave 7) exemplar: APG tabs (automatic activation) — role=tablist/tab/tabpanel, roving tabindex, ←/→/Home/End, aria-controls/labelledby, focusable panels; slots-only API. 0a render test; app 0b green + AAA CI (#250) |
| navbar | proven | ✅ | ✅ | Navigation band (Wave 7): `<nav>` landmark (i18n label) + APG disclosure mobile menu (hamburger aria-expanded/controls + Escape + outside-click, target-based controller; added the missing menu panel); aria-current on active link. 0a render test; app 0b green + AAA CI (#251) |
| breadcrumb | proven | ✅ | ✅ | Navigation band (Wave 7): `<nav aria-label>` landmark (i18n label) + ol/li; current page aria-current=page (not a link); decorative aria-hidden separators; focus-visible links. 0a render test; app 0b green + AAA CI (#252) |
| pagination | proven | ➖ | ✅ | Navigation band (Wave 7): NOT a custom component — leans on Pagy 43 `@pagy.series_nav` (accessible: aria-label/aria-current/rel) + design-system CSS in the host app (`.pagy.series-nav`), AAA-proven on a real paginated view. The experimental `PaginationComponent` template is superseded (do not adopt). |
| audio | proven | ✅ | ✅ | Media band (fail-loud `preload` guard; native `<audio>` controls). 0a + app 0b/AAA CI green (#259) |
| video | proven | ✅ | ✅ | Media band (fail-loud track-`kind` guard; `<track>` captions; native controls). 0a + app 0b/AAA CI green (#259) |
| gallery | proven | ✅ | ✅ | Media band (`<figure>`→focusable `<button>` trigger [2.1.1]; lightbox reuses the `modal` `<dialog>` via `EXTRA_STIMULUS` — focus-trap/escape/restore; caption off text-over-image → semantic surface; `alt` required when `lightbox:`). 0b asserts open/focus-in/Escape-restore. 0a + app 0b/AAA CI green (#259) |
| carousel | proven | ✅ | ✅ | Media band (APG-basic ARIA: `aria-roledescription` carousel/slide + `aria-current` dots + live region; 44px prev/next + dots; compliant autoplay [pause/play + hover/focus suspend + `prefers-reduced-motion` + `aria-live` flip]; `focus-visible:ring`→`focus-ring`; **slide `min-w-full`→`w-full`+`overflow-hidden`** so wide images don't land partial; i18n). 0b asserts slide lands flush; pause/play 2.2.2 verified. 0a + app 0b/AAA CI green (#259) |
| embed | proven | ✅ | ✅ | Media band (i18n `unsupported` msg + per-provider iframe titles; render-time title; `bg-black` letterbox commented; **`CGI.parse`→`URI.decode_www_form`** — Ruby 4.0 removed `CGI.parse`, `watch?v=`/maps `?q=` 500'd). 0a + app 0b/AAA CI green (#259) |
| accordion | proven | ✅ | ✅ | Disclosure-band exemplar — box-shadow `focus-visible:ring`→AAA `focus-ring`; decorative aria-hidden chevron + corrected SVG attr keys (dead `stroke_width`→`"stroke-width"`, mirrors carousel); native webkit marker hidden; sidecar `.html.erb`→`call` (the lib's only sidecar — tabs precedent + generator guard); `**html_attrs` passthrough. 0a render test (10) + app 0b/AAA CI green (gem #38 / app #262) |
| collapsible | proven | ✅ | ✅ | Disclosure band (parallel fan-out) — CSS-only native `<details>`/`<summary>`; added the missing AAA `focus-ring` on the focusable summary. 0a (7) + app 0b/AAA CI green (gem #39 / app #264) |
| stepper | proven | ✅ | ✅ | Disclosure band — i18n status labels (`I18n.t` default:); fail-loud `coerce` on orientation + step status (mirrors indicator); **`role="img"` on the status circles so `aria-label` is legal (4.1.2)** — caught by the live-axe 0b, the 0a only checked the label was present (gem #40). 0a (11) + app 0b/AAA CI green (gem #39+#40 / app #264) |
| button_group | proven | ✅ | ✅ | Disclosure band — presentational `role="group"` segmented wrapper; optional `aria_label:`; formalize (0a + preview). 0a (8) + app 0b/AAA CI green (gem #39 / app #264) |
| toggle_group | proven | ✅ | ✅ | Disclosure band — REQUIRED accessible name (`aria_label`/`aria_labelledby`, mirrors scroll_area); fail-loud `type`; kept `role="group"` for single+multiple (items are `aria-pressed` buttons, not radios — a true radiogroup variant is deferred). 0a (12) + app 0b/AAA CI green (gem #39 / app #264) |
| sidebar | proven | ✅ | ✅ | Nav-remainder exemplar — `focus-ring` ×2 (toggle + items); named `<nav>` landmark (`label:`→`aria-label`, i18n default); i18n toggle. 0a (9) + app 0b/AAA CI green (gem #41 / app #265) |
| bottom_nav | proven | ✅ | ✅ | Nav-remainder — named `<nav>` landmark; added the missing `focus-ring` on items; `border-t`→semantic `border-border`. 0a (8) + app 0b/AAA CI green (gem #41 / app #265) |
| speed_dial | proven | ✅ | ✅ | Nav-remainder — `focus-ring` ×3; FAB disclosure `aria-controls` + controller-synced `aria-expanded`; i18n label; fail-loud `position`; **fixed a caller-`data:` attr-clobber that dropped the controller wiring**. 0a (12) + app 0b/AAA CI green (gem #41 / app #265) |
| mega_menu | proven | ✅ | ✅ | Nav-remainder — `focus-ring` ×2; disclosure aria (haspopup/expanded/controls); panel → named `<nav>`; documented **nav-disclosure, not `role="menu"`** (owns its `mega-menu` controller, not the shared menu). 0a (13) + app 0b/AAA CI green (gem #41 / app #265) |
| navigation_menu | proven | ✅ | ✅ | Nav-remainder — `focus-ring` ×3; named `<nav>` landmark; disclosure-flyout aria; fail-loud `align`; hover-driven nav owns its `navigation-menu` controller (not the shared menu). 0a (12) + app 0b/AAA CI green (gem #41 / app #265) |
| rating | proven | ✅ | ✅ | Final band — raw `yellow-400` → semantic `warning-icon` token; `role="img"` + i18n value name (color-filled stars alone fail 1.1.1); decorative stars aria-hidden. 0a (12) + app 0b/AAA (gem #42 / app #266) |
| qr_code | proven | ✅ | ✅ | Final band — FIXED broken generation (`<%= %>` ERB in the doc comment broke the Thor template generator → bare-Ruby examples); `role="img"` + required `alt`; `bg-white`→`bg-surface`. 0a (8) + app 0b/AAA (gem #42 / app #266) |
| chart | proven | ✅ | ✅ | Final band — text alternative (sr-only data `<table>` + `role="img"`/aria-label, WAI complex-image pattern); fail-loud `type`; OKLCH semantic series palette; Chart.js importmap pin. 0a (13) + app 0b/AAA (gem #42 / app #266) |
| resizable | proven | ✅ | ✅ | Final band — `focus-ring`; APG window-splitter keyboard resize (`role=separator` + aria-valuenow/orientation + arrow/Home/End in controller, was pointer-only); fail-loud `direction`; attr-clobber fix. 0a (14) + app 0b/AAA (gem #42 / app #266) |
| command | proven | ✅ | ✅ | Final band — APG combobox/listbox + `aria-activedescendant` (controller); raw `bg-black`→neutral; `focus-ring`; fail-loud `size`; attr-clobber fix. 0a (16) + app 0b/AAA (gem #42 / app #266) |
| input_otp | proven | ✅ | ✅ | Final band — FIXED broken paste (`window.clipboardData` `ReferenceError` in controller); `focus-ring`; `role=group` + per-digit i18n labels; `inputmode=numeric`/`autocomplete=one-time-code`; fail-loud `length`. 0a (16) + app 0b/AAA (gem #42 / app #266) |
| combobox | proven | ✅ | ✅ | Final band — APG combobox/listbox + `aria-activedescendant` (mirrors command); `focus-ring`; fail-loud `size`; attr-clobber fix. 0a (17) + app 0b/AAA (gem #42 / app #266) |
| calendar | proven | ✅ | ✅ | Final band — APG date grid (`role=grid/row/gridcell` via `display:contents` to keep the CSS grid) + roving-tabindex arrow nav (controller); date aria-labels; fail-loud `weekday_start`; outside-day `muted/50`→`muted` (the opacity dimmed AAA-muted below contrast). 0a (19) + app 0b/AAA (gem #42 / app #266) |
| date_picker | proven | ✅ | ✅ | Final band — disclosure aria (removed a false `aria-modal`); Escape/focus-return (controller); label + format hint; fail-loud `format`; renders the hardened `calendar`. 0a (17) + app 0b/AAA (gem #42 / app #266) |
| timepicker | proven | ✅ | ✅ | Final band — `role=spinbutton` hour/minute/AM-PM (chosen over listbox); `focus-ring` ×3; disclosure aria; fail-loud `format`; attr-clobber fix. 0a (23) + app 0b/AAA (gem #42 / app #266) |
| wysiwyg | hardened | ✅ | ➖ | Final band — **gem-0a-only, SUPERSEDED in this app by Lexxy** (no app adoption). Template still hardened: editor `role=textbox`+label; named toolbar buttons + `aria-pressed`; `focus-ring`; fail-loud `adapter`. 0a (14) |
| toaster | hardened | ✅ | ➖ | Final band — **gem-0a-only, SUPERSEDED in this app by `shared/_toasts`** (no app adoption). Template still hardened: 6 raw-palette → tinted signal tokens (alert/banner model); per-severity live region; 44px dismiss + `focus-ring`; fail-loud `severity` (documents the flash-key collision). 0a (21) |

**Hardening program COMPLETE** — all 81 components are `proven` (0a + app 0b/AAA) or `hardened` (gem 0a; `wysiwyg`/`toaster` are superseded in this host and adopt no app 0b). No `experimental` components remain.

**Sibling templates to copy:** `alert` is the canonical Wave 1 reference. Copy its render test
(`test/render/alert_render_test.rb`), template-backed preview, and — for 0b — its preview-host
axe-AAA system spec shape (`spec/system/ui/alert_component_spec.rb` in the app: visit the preview
URL, scope axe to the component subtree by role, assert `axe_clean_in_both_themes?` with **no**
color-contrast exclude). `button` predates the preview-host 0b convention (its 0b was proven via
in-page adoption), so follow `alert` for the system-spec pattern, not `button`.
