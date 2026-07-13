# frozen_string_literal: true

# Fixture: direct-literal `visit` calls, no interpolation at all — the
# baseline shape every extractor handles trivially.
RSpec.describe "Lit component accessibility", type: :system do
  it "default passes AAA in both themes" do
    visit "/rails/view_components/ui/lit_component/default"
  end

  it "info passes AAA in both themes" do
    visit "/rails/view_components/ui/lit_component/info"
  end
end
