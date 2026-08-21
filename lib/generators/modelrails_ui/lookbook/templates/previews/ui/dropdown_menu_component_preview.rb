# frozen_string_literal: true

module UI
  # # Dropdown menu
  #
  # A button that opens a menu of actions (WAI-ARIA APG menu-button), driven by the
  # `menu` Stimulus controller. Open with the trigger; navigate with ↑/↓/Home/End or
  # type-ahead; Enter/Space/click activates; Escape/Tab/outside-click closes.
  #
  # ## Accessibility contract
  # - **Guarantees:** `aria-haspopup="menu"` + synced `aria-expanded`; `role="menu"`
  #   named by the trigger; `role="menuitem"` items with roving tabindex. Checkable items
  #   render `menuitemcheckbox`/`menuitemradio` with `aria-checked`; a sub-trigger adds
  #   `aria-haspopup="menu"` and owns a nested `role="menu"`.
  # - **You supply:** a `with_trigger` slot and `with_item` slots; `aria_label:` for
  #   icon-only triggers.
  #
  # ## Related
  # `context_menu` · `menubar`
  # @logical_path Overlays
  class DropdownMenuComponentPreview < ViewComponent::Preview
    include UIHelper

    # @!group Examples

    # Standard menu: a button trigger and a labelled menu with items, a disabled item,
    # a separator, and a link item.
    def basic
    end

    # `side:` and `align:` edge-align the menu to the trigger.
    def positioned
    end

    # Checkable items (`menuitemcheckbox` / `menuitemradio`) change state and keep the menu
    # open, so a multi-select view menu is usable in one pass. `tone: :danger` marks a
    # destructive action.
    def checkable_items
    end

    # A nested menu. The sub-trigger stays part of the parent's arrow-key rotation;
    # ArrowRight/Enter opens the submenu, ArrowLeft/Escape closes it.
    def submenus
    end

    # @!endgroup

    # @!group Reference

    # Edit `side` and `align` live to explore placement.
    # @param side select [bottom, top]
    # @param align select [start, end]
    def playground(side: :bottom, align: :start)
      render_with_template(locals: {side: side.to_sym, align: align.to_sym})
    end

    # @!endgroup
  end
end
