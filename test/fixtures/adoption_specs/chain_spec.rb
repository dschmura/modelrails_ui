# frozen_string_literal: true

# Fixture: chained-constant shape found for real in modelrails_base's
# range_component_spec.rb — a second constant is built by interpolating a
# first (`SOLO_SCENARIO = "#{PREVIEW}/solo"`), then referenced BARE (no
# quotes, no `#{}` at all) as the whole `visit` argument. A resolver that
# only expands `#{CONST}` inside string literals never even looks at this
# line — it has neither the literal path substring nor a `#{` on it — and
# silently drops it.
RSpec.describe "Chain component accessibility", type: :system do
  PREVIEW = "/rails/view_components/ui/chain_component"
  SOLO_SCENARIO = "#{PREVIEW}/solo"

  it "solo passes AAA in both themes" do
    visit SOLO_SCENARIO
  end
end
