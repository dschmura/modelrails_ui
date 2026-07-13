# frozen_string_literal: true

# Fixture: string-rocket-keyed hash loop shape found for real in
# modelrails_base's alert_component_spec.rb and badge_component_spec.rb —
# `{"scenario" => role}.each`, not `%w[...]`. The extractor's loop-expansion
# must recognize this literal too, or exactly the flagship (best-audited,
# many-scenario) components undercount.
RSpec.describe "Hashloop component accessibility", type: :system do
  {
    "default" => "status",
    "info" => "status"
  }.each do |scenario, role|
    it "#{scenario} has role=#{role} and passes AAA in both themes" do
      visit "/rails/view_components/ui/hashloop_component/#{scenario}"
    end
  end
end
