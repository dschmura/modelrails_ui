# frozen_string_literal: true

module UI
  # # Toaster
  #
  # A fixed-position stack of ephemeral, auto-dismissing toast notifications
  # (Sonner-style). Placed once in the layout; each toast is a tinted-surface card
  # with an i18n-named, focus-ringed, 44px dismiss `<button>`.
  #
  # > **Superseded in this app.** This host has its own flash/toast pipeline
  # > (`shared/_toasts`) — like pagination → Pagy, the gem `toaster` is hardened
  # > gem-side but NOT adopted here. Use `shared/_toasts` for real flashes.
  #
  # ## Use when
  # - A stack of transient, self-dismissing confirmations layered over the page
  #   ("Profile saved", "Copied") — fired via the `with_toast` slot (server) or a
  #   `toaster:add` window event (client).
  #
  # ## Don't use when
  # - It's an inline message tied to surrounding content — use `alert`.
  # - It's a standing page-level announcement — use `banner`.
  #
  # ## Accessibility contract
  # - **Guarantees:** the stack is a live region (`role="status"`/`aria-live="polite"`,
  #   and `role="alert"`/`assertive` for the `danger` severity), AAA-contrast text on
  #   a tinted signal surface, and a real focusable dismiss `<button>` with an i18n
  #   accessible name, the `focus-ring` utility, and a 44px target.
  # - **You supply:** a `message` (and optional `title`) per toast, a valid `severity`,
  #   and the `toaster` Stimulus controller (ships co-located, auto-registered).
  #
  # ## Severity
  # The canonical signal axis — `default` · `info` · `success` · `warning` · `danger`
  # — each tinted (`bg-<signal>-surface` + `border-<signal>-border` + `text-<signal>`).
  # Aliases: `:destructive`/`:error` → `:danger`, `:alert` → `:warning` (the latter two
  # smooth the app `shared/_toasts` flash-key collision, where `:alert` means warning).
  class ToasterComponentPreview < ViewComponent::Preview
    include UIHelper

    # A neutral default toast on the raised surface — announced politely (role=status).
    def default
    end

    # The full signal axis stacked: info / success / warning / danger, each on its
    # tinted surface. The danger toast is the only assertive (role=alert) one.
    def severities
    end

    # A toast with an optional bold title above the message body.
    def with_title
    end

    # An error toast (severity: :danger) — the only urgent severity, announced
    # assertively so a failure interrupts.
    def danger
    end

    # The dismiss control is a real focusable <button> with an i18n accessible name
    # ("Dismiss"), the `focus-ring` utility, and a 44px target.
    def dismissible
    end

    # ## Don't — a raw-palette / unnamed toast
    #
    # A hand-rolled toast with raw palette colors (border-green-500) and a bare
    # icon-only close button is an unnamed control on an off-system surface. The
    # component always tints with signal tokens and names its dismiss control.
    # @label Don't · raw palette + unnamed dismiss
    def dont_raw_palette
    end
  end
end
