# Accessibility scope

modelrails_ui is built to **WCAG 2.2 AA**, and holds itself to **AAA wherever a
component library controls the outcome**. This page says which AAA criteria
those are, what checks each one, and which belong to your app.

## Why the claim is scoped

WCAG conformance applies to whole pages, not components. Many AAA criteria
are about content the gem never sees, such as reading level, sign language for
video, and whether a link's text makes sense on its own. The W3C also advises
against requiring AAA across an entire site, because some content cannot meet
every AAA criterion. A component library that claimed "WCAG 2.2 AAA" outright
would be promising something only your pages can deliver.

## What checks A and AA

Every component's Lookbook preview is audited with axe-core in modelrails_base,
a real app with compiled CSS, in both themes. The audit uses every A and AA
rule through WCAG 2.2. This gem's browser tests cover what only happens once
JavaScript runs: keyboard paths, focus movement, and ARIA a controller keeps in
sync. See [testing.md](testing.md) for what each test lane can and cannot
prove.

Automated rules catch only part of A and AA. Reading order, a heading outline
that makes sense, and whether an announcement actually fires still need a
person and a screen reader.

## AAA, criterion by criterion

axe-core ships three AAA rules in total: enhanced contrast (1.4.6), identical
links with the same purpose (2.4.9), and meta refresh with no exceptions. It
has none for any AAA criterion added in WCAG 2.1 or 2.2. Every other row below
is either checked by a test written for it or not checked at all, and the table
says which.

| Status | Meaning |
| --- | --- |
| **Checked** | A test fails if this regresses. |
| **Held** | The components are built to it, but nothing fails if one stops. |
| **Your app** | It depends on content or flows the gem does not own. |
| **Gap** | Known not to hold today. |

| Criterion | Status | How |
| --- | --- | --- |
| 1.2.6 Sign Language (Prerecorded) | Your app | Media content. |
| 1.2.7 Extended Audio Description | Your app | Media content. |
| 1.2.8 Media Alternative (Prerecorded) | Your app | `video` renders the `<track>` elements you pass. The alternative itself is content. |
| 1.2.9 Audio-only (Live) | Your app | Media content. |
| 1.3.6 Identify Purpose | Your app | Components name their landmarks, and `input_otp` sets `autocomplete="one-time-code"`. Marking the purpose of your own regions and fields is up to you. |
| 1.4.6 Contrast (Enhanced) | **Checked** | `test/test_aaa_contrast.rb` and `test/test_hue_ramp_contrast.rb` compute 7:1 from the shipped tokens, in both themes. modelrails_base's axe audit checks every rendered component preview. One pair is pinned as below AAA: `text-interactive` on `surface-sunken` measures 6.86:1. No component renders that pair, but your own markup can. |
| 1.4.7 Low or No Background Audio | Your app | Media content. |
| 1.4.8 Visual Presentation | Your app | Line length, line spacing and justification belong to your page layout and prose styles. |
| 1.4.9 Images of Text (No Exception) | Your app | No component renders text as an image. |
| 2.1.3 Keyboard (No Exception) | **Checked** / Held | The browser tests drive the keyboard path for `dropdown_menu`, `menubar`, `tabs`, `dialog`, `drawer`, `popover`, `combobox`, `command`, `date_picker`, `timepicker`, `sidebar` and `checkbox`. The other components are built to it without a browser test. |
| 2.2.3 No Timing | **Gap** | `toaster` dismisses a toast after 4 seconds by default, with no pause on hover or focus. Pass `duration: 0` to keep a toast until it is dismissed. `carousel` does not autoplay unless you ask it to. |
| 2.2.4 Interruptions | Your app | Toasts announce politely, except `danger`, which is assertive. When to interrupt is your decision. |
| 2.2.5 Re-authenticating | Your app | `form_draft` saves unsaved form input in the browser and offers it back when the form is next opened. Whether a session expiry sends people back to that form is up to your app. |
| 2.2.6 Timeouts | Your app | Session policy. |
| 2.3.2 Three Flashes | Held | No component flashes. |
| 2.3.3 Animation from Interactions | **Checked** | `test/test_motion_respects_reduced_motion.rb` requires every transform-capable transition or animation to sit behind `motion-safe:`. The spinner is exempt as essential motion (see [components/spinner.md](components/spinner.md)). |
| 2.4.8 Location | Your app | `breadcrumb` and the `aria-current` set by the navigation components give you the means. |
| 2.4.9 Link Purpose (Link Only) | Your app | Link text is content. modelrails_base's axe audit includes the one automated rule for it. |
| 2.4.10 Section Headings | Your app | `card` takes the heading level from you rather than guessing. |
| 2.4.12 Focus Not Obscured (Enhanced) | Not checked | Fixed and sticky components (`navbar`, `bottom_nav`, `speed_dial`, the toast region) can cover a focused control. Nothing tests for this yet. |
| 2.4.13 Focus Appearance | **Checked** / Gap | `test/test_focus_indicator_contrast.rb` holds the `focus-ring` utility to a solid, offset outline of at least 2px that measures 3:1 or more against every surface in both themes (the lowest is 6.86:1). The gap: `data_table`'s search field, and the superseded `pagination` template, still draw focus with a box-shadow ring instead of `focus-ring`. |
| 2.5.5 Target Size (Enhanced) | **Checked**, in part | `test/test_target_size.rb` pins 44px on the controls it names, and the 44px `min-h-input` token sizes the rest. modelrails_base's axe audit checks only the 24px AA figure. |
| 2.5.6 Concurrent Input Mechanisms | Held | No component limits input to one modality. |
| 3.1.3 Unusual Words | Your app | Content. |
| 3.1.4 Abbreviations | Your app | Content. |
| 3.1.5 Reading Level | Your app | Content. |
| 3.1.6 Pronunciation | Your app | Content. |
| 3.2.5 Change on Request | Held | No component changes context on its own. |
| 3.3.5 Help | Your app | Form components accept `describedby` for hints. |
| 3.3.6 Error Prevention (All) | Your app | `error_summary` and `form_draft` help, but whether a submission can be reviewed or reversed is your flow. |
| 3.3.9 Accessible Authentication (Enhanced) | Your app | `input_otp` supports autofill and paste. The sign-in flow is yours. |

## Keeping this page true

When a row changes status, update it in the same PR as the test or fix that
changed it. A "Checked" row names its test, so a test that is renamed or
removed shows up here as a broken reference.
