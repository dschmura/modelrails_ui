# Rating Input

Interactive star rating — hover to preview, click to select. Submits the chosen value via a `<form>` hidden input or directly via AJAX.

## Installation

```bash
rails g modelrails_ui:add rating_input
```

Creates:
- `app/components/ui/rating_input_component.rb`
- `app/javascript/controllers/rating_controller.js`

Register the controller in your Stimulus setup:

```js
import RatingController from "./rating_controller"
application.register("rating", RatingController)
```

## Usage

### Standalone (no submission)

```erb
<%= ui :rating_input, value: 3 %>
```

### Inside a form

Pass `name:` to render a hidden `<input>` that is submitted with the form:

```erb
<%= form_with url: reviews_path do |f| %>
  <%= ui :rating_input, value: 0, name: "review[rating]" %>
  <%= f.submit "Submit" %>
<% end %>
```

### Direct AJAX submission

Pass `url:` to have the controller `POST { value: N }` as JSON on every click:

```erb
<%= ui :rating_input, value: @post.rating, url: rate_post_path(@post) %>
```

Server receives: `{ "value" => 4 }` with `Content-Type: application/json` and the CSRF token.

## API

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `value` | Integer | `0` | Pre-selected rating. Clamped to `0..max`. |
| `max` | Integer | `5` | Total number of stars |
| `name` | String | `nil` | Hidden input `name` for form submission |
| `url` | String | `nil` | Endpoint for AJAX `POST` on click |
| `**html_attrs` | Hash | — | Forwarded to the wrapper `<div>` |

`name:` and `url:` can be used together or independently.

## Stimulus controller

The `rating_controller.js` manages three interactions:

| Action | Trigger | Behaviour |
|--------|---------|-----------|
| `preview` | `mouseenter` on a star | Highlights stars up to the hovered index |
| `resetPreview` | `mouseleave` on a star | Restores the committed value |
| `select` | `click` on a star | Commits the value, updates hidden input, optionally POSTs to `url` |

## When to use

- You need a quick 1..max star score (a product review, a satisfaction score)
  either posted in a form (`name:`) or sent straight to an endpoint (`url:`).

## When not to use

- The scale isn't ordinal stars, or you need half/decimal precision — use a
  `ui :select` or a numeric input.
- The choice is binary on/off — use `ui :toggle` or `ui :switch`.

## Accessibility contract

- **Guarantees:** the star group exposes an accessible name (`role="group"` +
  `aria-label`, default "Rating"), each star is a labelled
  (`aria-label "Rate N of max"`) `<button>` with a >=44px hit target (AAA 2.5.5)
  even though the visual star is 24px, and the hidden input (when `name:` is
  given) carries the value so it posts with the form.
- **You supply:** an optional group `label:` (overrides the default), the
  initial `value:`, `max:` star count, and either `name:` (form post) or
  `url:` (direct submit).

No fail-loud guard — there is no enum axis to validate; `value` is clamped to
0..max and `max` is a plain integer count.

Future enhancement (intentionally not done here): a full
`role="radiogroup"`/`role="radio"` restructure with roving-tabindex keyboard
selection. That is a larger redesign; today the group is announced as a named
group of labelled buttons, which is the accessible baseline.
