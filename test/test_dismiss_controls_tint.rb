# frozen_string_literal: true

require "test_helper"

# A dismiss control tints on hover; it never fades.
#
# An opacity fade reads as DISABLED — the rule already stated beside
# `.btn-text-icon` — and on a tinted chip it drags the icon toward the surface
# behind it, the one direction that loses contrast, on the control most likely
# to be clicked in a hurry (#256).
#
# The icon is non-text, so its floor is 3:1 rather than 7:1. That is the
# distinction that made this the gem's half of modelrails_base#1068 and not the
# same bug: the host's three TEXT controls genuinely failed AAA hovered; these
# never did.
class TestDismissControlsTint < Minitest::Test
  TEMPLATES = File.expand_path("../lib/generators/modelrails_ui/add/templates", __dir__)
  BANNER = "#{TEMPLATES}/banner/banner_component.rb.tt"
  TOAST_RB = "#{TEMPLATES}/toaster/toaster_component.rb.tt"
  TOAST_JS = "#{TEMPLATES}/toaster/toaster_controller.js"

  # A hover that REDUCES opacity. `group-hover:opacity-100` is the opposite —
  # gallery reveals a caption that way — and an earlier draft of this guard
  # reported it as a fade. The rule is about dimming, so the pattern says so.
  FADES_ON_HOVER = /hover:opacity-(?!100\b)\d+/

  def test_no_template_fades_a_control_on_hover
    offenders = Dir.glob("#{TEMPLATES}/*/*").grep(/\.rb\.tt\z|\.js\z/).select do |path|
      File.read(path).match?(FADES_ON_HOVER)
    end.map { |p| p.delete_prefix("#{TEMPLATES}/") }

    assert_empty offenders, <<~MSG
      These fade a control on hover. A fade reads as disabled, and on a tinted
      surface it pulls the icon toward its own ground:

        #{offenders.join("\n  ")}

      Tint instead, keyed by the variant or severity whose ground it sits on.
    MSG
  end

  # The toaster ships TWICE — a server-rendered component and a client-built
  # one — and the two have drifted before. They render the same control, so the
  # severity-to-hover mapping has to match exactly.
  def test_the_toasters_two_copies_agree_on_the_hover_tint
    rb = File.read(TOAST_RB).scan(/close_hover:\s*"hover:bg-([a-z-]+)"/).flatten
    js = File.read(TOAST_JS)
      .slice(/const closeHoverCls = \{(.*?)\}/m).to_s
      .scan(/"hover:bg-([a-z-]+)"/).flatten

    assert_equal 5, rb.size, "expected five severities in toaster_component.rb.tt, found #{rb.size}"
    assert_equal rb, js, <<~MSG
      The two toaster copies disagree about the dismiss hover:

        toaster_component.rb.tt: #{rb.join(", ")}
        toaster_controller.js:   #{js.join(", ")}

      They render the same control; a difference here ships as one behaviour on
      first paint and another on every toast raised afterwards.
    MSG
  end

  def test_the_banner_keys_its_dismiss_hover_to_every_variant
    src = File.read(BANNER)
    variants = src.slice(/VARIANTS = \{(.*?)\}\.freeze/m).to_s.scan(/^\s+(\w+):\s+"/).flatten
    hovers = src.slice(/DISMISS_HOVER = \{(.*?)\}\.freeze/m).to_s.scan(/^\s+(\w+):\s+"/).flatten

    refute_empty variants, "no VARIANTS parsed from banner_component.rb.tt"
    assert_equal variants.sort, hovers.sort,
      "every banner variant needs a dismiss hover for its own ground; " \
      "variants: #{variants.join(", ")} / hovers: #{hovers.join(", ")}"
  end
end
