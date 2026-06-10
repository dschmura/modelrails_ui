# frozen_string_literal: true

module UI
  # # Wysiwyg
  #
  # A rich-text editor wrapper that picks between **Trix** (default, via ActionText)
  # and **Quill** (`adapter: :quill`). The Trix path renders an explicit, accessible
  # toolbar of named toggle buttons; the Quill path renders its own toolbar via the
  # bundled Stimulus controller.
  #
  # > **Note:** SUPERSEDED in this app by **Lexxy** (Lexical-based rich text), the
  # > way pagination defers to Pagy and toasts to `shared/_toasts`. Kept correct +
  # > accessible for other consumers; hardened gem-side only (no app adoption).
  #
  # ## Use when
  # - You need a Trix/Quill rich-text field bound to a form parameter and aren't
  #   already standardized on a Lexical editor.
  #
  # ## Don't use when
  # - This app composes Lexxy directly — reach for that instead.
  #
  # ## Accessibility contract
  # - **Guarantees:** a labelled editor region (`role="textbox"`, i18n `aria-label`,
  #   override via `label:`), a named `role="toolbar"` with i18n-labelled toggle
  #   buttons carrying `aria-pressed` + the AAA `focus-ring`, and semantic tokens.
  # - **You supply:** a form-field `name:`, an optional initial `value:`, and a
  #   valid `adapter:` (`:trix` | `:quill` — an unknown value raises).
  class WysiwygComponentPreview < ViewComponent::Preview
    include UIHelper

    # The default Trix editor with the accessible formatting toolbar.
    def default
    end

    # Pre-filled with initial HTML content via `value:`.
    def with_value
    end

    # Toolbar suppressed (`toolbar: false`) — a bare, still-labelled editor region.
    def without_toolbar
    end

    # The Quill adapter — renders its own toolbar via the bundled controller.
    def quill
    end
  end
end
