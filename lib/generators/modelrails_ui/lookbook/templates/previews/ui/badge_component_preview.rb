# frozen_string_literal: true

module UI
  # # Badge
  #
  # A small status/category label — a compact pill that tags surrounding content.
  # Renders a `<span>`, or an `<a>` when `href:` is given (a clickable tag/filter link).
  #
  # ## Use when
  # - A short inline label that classifies or annotates nearby content (status pill,
  #   category tag, small count).
  #
  # ## Don't use when
  # - It's a real action — use `UI::ButtonComponent` (or `button_to` for non-GET).
  #
  # ## Accessibility contract
  # - **Guarantees:** AAA-contrast text on 9 of the 10 shipped cells (`soft`/`neutral`
  #   pending the consuming app's 0b axe row), including the adaptive signal treatments
  #   (`danger`/`success`/`info`/`warning`) that stay legible in dark mode.
  # - **You supply:** an accessible name when the badge conveys status not already in
  #   the surrounding text, and a valid `variant` (an unknown one raises in development).
  #
  # ## Cells (variant × tone)
  # Two-axis API: `variant:` (shape — `solid` · `soft` · `outline` · `ghost` · `link`)
  # × `tone:` (signal — `primary` · `neutral` · `info` · `success` · `warning` ·
  # `danger`). Only the 10 shipped cells render; signal tones live on the SOFT
  # variant as tinted chips (soft `*-surface` + saturated `text-<level>`, matching
  # the alert + toast cards). Legacy flat `variant:` values still render via a
  # deprecation shim — write the two axes in new code.
  # @logical_path Feedback & Status
  class BadgeComponentPreview < ViewComponent::Preview
    include UIHelper

    # @!group Overview

    # Every shipped variant × tone cell on one screen — 9 AAA-proven, soft/neutral pending.
    def showcase
    end

    # @!endgroup

    # @!group Examples

    # The default, high-emphasis label — the `solid`/`primary` cell (a bare call).
    def default
    end

    # Lower-emphasis label — the `soft`/`primary` cell (the legacy `secondary`).
    def secondary
    end

    # Muted chip for draft-style pills — the two-axis `[:soft, :neutral]` cell, pending
    # the consuming app's 0b axe row (see the class docblock).
    def neutral
    end

    # Informational signal — the `soft`/`info` tinted chip.
    def info
    end

    # Success / completed status — the `soft`/`success` tinted chip.
    def success
    end

    # Warning status — the `soft`/`warning` tinted chip (soft amber surface + dark amber text).
    def warning
    end

    # Error / removed / failed status — the `soft`/`danger` tinted chip; keeps a danger focus ring.
    def danger
    end

    # The legacy-shim demo: historical flat values (here `variant: :destructive`)
    # still resolve to their cell (`soft`/`danger`) byte-identically. New code
    # writes the two axes.
    def destructive
    end

    # Outlined label — the `outline`/`neutral` cell, a border with no fill.
    def outline
    end

    # Minimal label — the `ghost`/`neutral` cell; no fill, no border, surface tint on hover when linked.
    def ghost
    end

    # Link-styled label — the `link`/`primary` cell; pair with `href:` for a clickable tag/filter.
    def link
    end

    # Linked badge: pass `href:` and the component renders an `<a>`.
    def link_href
    end

    # @!endgroup

    # @!group Reference

    # Edit `label` and the two-axis `variant`/`tone` cell live. Only the 10 shipped
    # cells are offered — 9 AAA-proven, plus `soft/neutral` pending the consuming app's
    # 0b axe row (signals live on the SOFT variant as tinted chips; an unproven pairing
    # raises in dev).
    # @param label text
    # @param cell select [solid/primary, soft/primary, soft/info, soft/success, soft/warning, soft/danger, soft/neutral, outline/neutral, ghost/neutral, link/primary]
    def playground(label: "Badge", cell: "soft/primary")
      variant, tone = cell.split("/")
      ui :badge, label, variant: variant.to_sym, tone: tone.to_sym
    end

    # ## Don't — a badge as an action
    #
    # A badge is presentational. Don't wire a click handler onto a bare badge to fake
    # a button — screen-reader and keyboard users get no interactive affordance.
    # Use `UI::ButtonComponent` for actions, or pass `href:` for genuine navigation.
    # @label Don't · badge as an action
    def dont_action
    end

    # @!endgroup
  end
end
