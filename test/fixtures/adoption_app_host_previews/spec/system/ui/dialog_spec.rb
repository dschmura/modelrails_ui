# frozen_string_literal: true

# Visits the HOST's own scenario names (zzz_host_only_a/b), not the gem's
# (default/large). If AuditCoverage's M ever regressed to sourcing from
# GEM_PREVIEWS again, these visits could never intersect it and coverage
# would be stuck at 0 regardless of what this spec does.
RSpec.describe "dialog", type: :system do
  it "renders zzz_host_only_a" do
    visit "/rails/view_components/ui/dialog_component/zzz_host_only_a"
  end

  it "renders zzz_host_only_b" do
    visit "/rails/view_components/ui/dialog_component/zzz_host_only_b"
  end
end
