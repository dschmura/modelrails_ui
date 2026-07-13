# frozen_string_literal: true

require "test_helper"
require "modelrails_ui/adoption/adapter_map"

class TestAdoptionAdapterMap < Minitest::Test
  Map = ModelrailsUi::Adoption::AdapterMap

  def test_ships_typed_defaults_for_the_zero_call_site_components
    assert_equal({kind: :css_prefix, value: ".btn-"}, Map::DEFAULTS.fetch("button"))
    assert_equal({kind: :helper, value: "avatar_for"}, Map::DEFAULTS.fetch("avatar"))
    assert_equal({kind: :partial, value: "shared/_modal"}, Map::DEFAULTS.fetch("dialog"))
    assert_equal :method, Map::DEFAULTS.fetch("input")[:kind]
  end

  def test_fork_overrides_merge_per_key_without_discarding_defaults
    merged = Map.merged("billing_widget" => {kind: :helper, value: "billing_for"})

    assert_equal({kind: :helper, value: "billing_for"}, merged.fetch("billing_widget"))
    assert merged.key?("button"), "a fork override must not drop the shipped defaults"
  end
end
