# frozen_string_literal: true

module UI
  # # Pagination
  #
  # A page-number nav for splitting a list across pages. Lean Pagy wrapper — see
  # COMPONENT_STATUS.md.
  #
  # ## Use when
  # - You have a paginated collection and want prev/next + numbered page links.
  #
  # ## Don't use when
  # - The list fits on one page — the component renders nothing when `total_pages <= 1`.
  #
  # ## Accessibility contract
  # - **Guarantees:** a named `<nav aria-label="Pagination">` landmark; the current
  #   page is `aria-current="page"`, rendered as text, not a link; prev/next are
  #   labelled links (`aria-label="Previous page"` / `"Next page"`).
  # - **You supply:** `current_page`, `total_pages`, and a `url:` callable that maps
  #   a page number to a path.
  # @logical_path Navigation
  class PaginationComponentPreview < ViewComponent::Preview
    include UIHelper

    # Page 3 of 10 (prev/next links, numbered pages, current page marked).
    def default
    end
  end
end
