# frozen_string_literal: true

# Fixture: loop-driven `#{scenario}` interpolation over a `%w[...]` literal —
# a naive regex sees one `visit` line and undercounts to 1/M; the extractor
# must expand the driving literal's elements to get 3/3.
RSpec.describe "Loop component accessibility", type: :system do
  %w[default info success].each do |scenario|
    it "#{scenario} passes AAA in both themes" do
      visit "/rails/view_components/ui/loop_component/#{scenario}"
    end
  end
end
