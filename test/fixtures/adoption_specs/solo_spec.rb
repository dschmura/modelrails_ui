# frozen_string_literal: true

# Fixture: default-only guard case — a single scenario, no interpolation.
RSpec.describe "Solo component accessibility", type: :system do
  it "default passes AAA in both themes" do
    visit "/rails/view_components/ui/solo_component/default"
  end
end
