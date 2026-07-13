# frozen_string_literal: true

# Fixture: the loop variable is driven by a runtime method call, not a
# literal `%w[...]` or hash the extractor can read statically. This MUST
# land in `unresolved`, never be silently dropped or miscounted as 0
# coverage — that silent-drop is the exact failure mode this unit exists to
# avoid.
RSpec.describe "Unresolved component accessibility", type: :system do
  DynamicScenarios.for(:unresolved).each do |scenario|
    it "#{scenario} passes AAA in both themes" do
      visit "/rails/view_components/ui/unresolved_component/#{scenario}"
    end
  end
end
