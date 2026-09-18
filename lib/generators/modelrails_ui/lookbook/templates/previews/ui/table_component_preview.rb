# frozen_string_literal: true

module UI
  # # Table
  #
  # A **server-rendered** data table: caption, toolbar, header, body and footer
  # slots around a plain `<table>`. Sorting, filtering and paging are the
  # caller's business — a GET form, pagy, your own links.
  #
  # ## Use when
  # - The data is paged or sorted on the server, and each change is a request.
  # - The set is larger than the page, so the browser never has all of it.
  #
  # ## Don't use when
  # - Every row is already on the page and you want in-browser sort/filter —
  #   that is `data_table`, this component's client-side counterpart.
  # - The rows have no columns — use a `list_group`.
  #
  # ## Accessibility contract
  # - **Guarantees:** a required `caption:` — the table's accessible name, which
  #   a blank value refuses rather than defaults; `scroll: :horizontal` wraps
  #   ONLY the `<table>` in a focusable, named region (WCAG 2.1.1), named
  #   distinctly from the caption so a screen reader does not announce the same
  #   words twice; header cell classes live on a shared constant (`TH`) at the
  #   AAA 44px row height, so a sortable header matches a plain one.
  # - **You supply:** the `<th>` cells (with `scope="col"`) via `with_header`,
  #   the `<tr>` rows via `with_body`, and any toolbar/footer content.
  # @logical_path Data Display
  class TableComponentPreview < ViewComponent::Preview
    include UIHelper

    # @!group Examples

    # The plain card: a visually hidden caption, a header row and a body.
    def default
    end

    # Toolbar and footer are the card's own bands — the toolbar inside the top
    # border, the footer below the table — so the table's context and its pager
    # sit inside the card instead of floating above and below it.
    def with_toolbar_and_footer
    end

    # `scroll: :horizontal` scrolls the COLUMNS only. The toolbar's controls and
    # the footer's pager stay put, which is the whole point: wrapping the entire
    # component in a scroll region carries them off-screen at phone width.
    # Narrow the preview pane to see it.
    # @label Scrolling · wide table
    def scrolling
    end

    # @!endgroup

    # @!group Reference

    # ## Don't — a table with no caption
    #
    # A table with no accessible name leaves a screen-reader user with a grid of
    # values and no statement of what they are. This component refuses to render
    # without one, so the failure is a loud `ArgumentError` at development time
    # rather than a silent gap in production. Shown here as the correct form.
    # @label Don't · nameless table
    def dont_nameless
    end

    # @!endgroup
  end
end
