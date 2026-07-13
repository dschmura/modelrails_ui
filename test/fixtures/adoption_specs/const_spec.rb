# frozen_string_literal: true

# Fixture: a file-level string constant carries the component identity, and
# `visit` interpolates it as a base path — a naive regex never sees the
# literal "/rails/view_components/ui/const_component" substring on the
# `visit` line itself and undercounts to 0/M.
RSpec.describe "Const component accessibility", type: :system do
  PREVIEW = "/rails/view_components/ui/const_component"

  it "off passes AAA in both themes" do
    visit "#{PREVIEW}/off"
  end

  it "on passes AAA in both themes" do
    visit "#{PREVIEW}/on"
  end
end
