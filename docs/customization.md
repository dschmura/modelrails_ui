# Customizing ModelrailsUi

ModelrailsUi follows the shadcn/ui philosophy: **you own the code**. Components are copied into your app by the generator, so you can change anything without forking the gem.

There are three levels of customization, from lightest to deepest:

---

## Level 1 — Design tokens (colors, radius, spacing)

All visual properties are driven by CSS variables defined in `app/assets/stylesheets/modelrails_ui.css` (exact path depends on your setup — see `rails g modelrails_ui:install`).

Tokens come in **three layers**, and which one you override decides how far the
change reaches:

1. **Palette ramps** — `--primary-50` … `--primary-950`, and the same for
   `--secondary-*` and `--neutral-*`. Raw colour with no meaning attached.
2. **Semantic tokens** — `--color-interactive`, `--color-surface`,
   `--color-text-body`, and friends. Each names a *role* and points at a ramp step.
3. **Tailwind utilities** — the semantic layer is registered in `@theme inline`, so
   `bg-surface-raised` and `text-text-body` resolve to it in your markup.

**To rebrand, override the ramp.** The semantic layer re-points automatically, in
both themes, and the AAA pairings stay intact:

```css
/* app/assets/stylesheets/modelrails_ui.css */

:root {
  --primary-800: oklch(0.44 0.11 286);  /* light-mode interactive */
  --primary-300: oklch(0.82 0.11 286);  /* dark-mode interactive */
}
```

Override a **semantic** token when you want to move one role without touching the
palette — a warmer page surface, say, but the same brand colour:

```css
:root {
  --color-surface: oklch(0.98 0.01 90);
}
```

### The tokens

Which surface to use where is a rule, not a preference — see
[design-tokens.md](design-tokens.md).

| Surface | Role |
|---|---|
| `--color-surface` | The page |
| `--color-surface-raised` | A container sitting on the page |
| `--color-surface-overlay` | A container floating above it |
| `--color-surface-sunken` | A well inside a container |

| Text | Role |
|---|---|
| `--color-text-heading` | Headings and emphasis |
| `--color-text-body` | Body copy |
| `--color-text-muted` | De-emphasised copy — see the AAA note below |
| `--color-text-on-interactive` | Text on a solid interactive fill |

| Interactive | Role |
|---|---|
| `--color-interactive` | Links, primary buttons, active states |
| `--color-interactive-hover` | Its hover state |
| `--color-interactive-subtle` | Tinted interactive backgrounds |
| `--color-interactive-focus` | The focus outline |
| `--color-accent` | The secondary accent |

Signals are canonical — `info`, `success`, `warning`, `danger` — and each has the
same shape: `--color-info`, `--color-info-surface`, `--color-info-border`,
`--color-info-icon`, and so on for the other three.

| Border | Role |
|---|---|
| `--color-border` | Default borders |
| `--color-border-strong` | Higher-contrast borders |
| `--color-border-focus` | Focused control borders |

### AAA is in the values, not on top of them

Every text/surface pair here clears WCAG 2.2 **AAA** (7:1), and the values are
chosen to make that true rather than to look a particular way.

The consequence that catches people out: **`--color-text-muted` resolves to the
same value as `--color-text-body`.** That is deliberate. A lighter grey would fall
below 7:1, so de-emphasis comes from size and weight instead. "Fixing" muted to
look lighter takes your app out of AAA silently — nothing will warn you.

### Sizing tokens

| Token | Utility | Used by |
|-------|---------|---------|
| `--form-input-height` | `min-h-input` | The 44px form-control floor (WCAG 2.2 AAA target size): inputs, selects, buttons via `.btn-touch-target` |

Write `min-h-input` in app code — it is registered in `@theme inline` and resolves to
`var(--form-input-height)`. The two legacy spellings, `min-h-11` and
`min-h-[var(--form-input-height)]`, resolve to the same 2.75rem today but are
deprecated: with a single named token, changing the input height (or auditing the
AAA invariant) has exactly one place to look.

### Colors use OKLCH

OKLCH gives perceptually uniform brightness. The format is `oklch(L C H)`:

- **L** — lightness `0` (black) → `1` (white)
- **C** — chroma (saturation) `0` (grey) → `~0.3+` (vivid)
- **H** — hue angle in degrees (`0` = red, `120` = green, `264` = indigo, `300` = purple)

Quick brand hues for the ramp. Keep the lightness and chroma — those are what hold
the AAA ratios — and move the hue angle only:

```css
/* Blue   */ --primary-800: oklch(0.44 0.11 250);
/* Green  */ --primary-800: oklch(0.44 0.11 145);
/* Purple */ --primary-800: oklch(0.44 0.11 300);
/* Orange */ --primary-800: oklch(0.44 0.11 50);
/* Red    */ --primary-800: oklch(0.44 0.11 15);
```

Changing lightness is where AAA breaks: `--color-interactive` was moved from
`--primary-700` to `--primary-800` precisely because 700 measured 5.93:1 against
white and 800 reaches 7.56:1.

### Dark mode

Dark mode is a class toggle, not a media query: `@custom-variant dark (&:where(.dark, .dark *))`.
Add `class="dark"` to `<html>` to activate it.

The `.dark` block re-points the **same semantic tokens** at different ramp steps —
the token names never change, only what they resolve to:

```css
.dark {
  --color-surface: oklch(0.2 0.02 286);      /* a tinted dark page */
  --color-interactive: var(--primary-300);   /* lighter, for contrast on dark */
}
```

Note the direction: light mode uses `--primary-800` for interactive and dark mode
uses `--primary-300`. Dark surfaces need a *lighter* interactive colour to stay at
7:1, which is why overriding the ramp rather than the semantic token is usually the
change you want — it keeps both ends consistent.

---

## Level 2 — Component classes

Each component file lives in `app/components/ui/` and is plain Ruby. The Tailwind classes are defined as constants at the top of the file — edit them directly:

```ruby
# app/components/ui/button_component.rb

BASE_CLASSES = "inline-flex items-center justify-center gap-2 rounded-md text-sm font-semibold ..."

VARIANTS = {
  default: "bg-primary text-primary-foreground hover:bg-primary/90",
  outline: "border bg-background hover:bg-accent",
  # Add a new variant:
  brand:   "bg-gradient-to-r from-indigo-500 to-purple-600 text-white hover:opacity-90"
}.freeze
```

Then use it:

```erb
<%= ui :button, "Subscribe", variant: :brand %>
```

### Adding a variant to Badge

```ruby
# app/components/ui/badge_component.rb
VARIANTS = {
  default:     "...",
  secondary:   "...",
  destructive: "...",
  outline:     "...",
  # Your additions:
  success: "border-transparent bg-green-500 text-white",
  warning: "border-transparent bg-yellow-400 text-foreground"
}.freeze
```

### Changing the tag or structure

Components use `content_tag` in `call` — you can change the HTML tag or structure freely:

```ruby
# Make Button render a <span> by default instead of <button>
def call
  content_tag(:span, content.presence || @label, class: component_classes, **@html_attrs)
end
```

---

## Level 3 — Per-instance overrides

Pass `class:` to any component to append Tailwind utilities to the generated classes. Your classes are added **after** the base classes, so they win:

```erb
<%# Wider button %>
<%= ui :button, "Continue", class: "w-full" %>

<%# Tighter card %>
<%= ui :card, class: "p-3 gap-3" %>

<%# Muted badge with extra spacing %>
<%= ui :badge, "Draft", variant: :outline, class: "ml-2 opacity-60" %>
```

This works because all components pass `@extra_class` last through the `cn()` helper, which joins and deduplicates class names.

---

## Theming example — full brand override

Suppose your brand is indigo with a warm dark mode. Move the **ramp**, not the
semantic tokens — the whole system re-points, in both themes:

```css
/* app/assets/stylesheets/modelrails_ui.css */

:root {
  /* Only the hue moves; lightness and chroma hold the AAA ratios. */
  --primary-300: oklch(0.82 0.11 286);
  --primary-800: oklch(0.44 0.11 286);
}

.dark {
  /* A warmer dark page. The interactive colour already follows the ramp above. */
  --color-surface:        oklch(0.21 0.02 286);
  --color-surface-raised: oklch(0.28 0.02 286);
}
```

No component files change — the semantic layer propagates the ramp everywhere
automatically, and both themes stay at AAA because the lightness steps did not move.

---

## Keeping components up to date

If a new version ships improvements to a component, re-run the generator with
`--force` to take them:

```bash
rails g modelrails_ui:add button --force
```

**This overwrites the file wholesale.** Anything you edited in place is gone, with
no merge and no warning — which sits in real tension with "you own the code" at the
top of this page. Both are true, and the way to hold them together is to be
deliberate about *where* a change lives:

| Change | Where it belongs | Survives `--force`? |
|---|---|---|
| Brand colour, surfaces, spacing | A token override (Level 1) | Yes — different file |
| One call site needs different utilities | `class:` on that call (Level 3) | Yes — your view |
| A component needs different behaviour everywhere | A subclass in your app that inherits from `UI::…` and overrides the one method | Yes — your file |
| Editing the generated file directly (Level 2) | — | **No** |

Level 2 is still the right answer when you genuinely want to own a component and
stop tracking upstream — just make that a decision rather than a surprise.

Before regenerating, **check the CHANGELOG for that component**. A release can
change a component's DOM shape or its i18n keys, and the entry will say so; the
generator will not.
