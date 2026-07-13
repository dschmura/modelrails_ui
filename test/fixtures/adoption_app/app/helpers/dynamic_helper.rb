# test/fixtures/adoption_app/app/helpers/dynamic_helper.rb
module DynamicHelper
  # Default arg is real code (not a comment), so it's the ONE piece of
  # evidence connecting :input to this dynamic dispatch. Without it, "input"
  # and "carousel" (genuinely absent) would be textually indistinguishable —
  # both would reach the dynamic fallback and misclassify identically.
  def render_dynamic(name = :input) = ui(name)   # dynamic → unknown
end
