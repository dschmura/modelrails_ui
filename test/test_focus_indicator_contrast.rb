# frozen_string_literal: true

require "test_helper"

# WCAG 2.4.13 Focus Appearance (AAA): the focus indicator is at least a 2px
# perimeter and differs from the unfocused pixels by 3:1.
#
# `focus-ring` is an OFFSET outline, so the pixels it replaces are the ground the
# control sits on, never the control itself. The ratio that matters is therefore the
# focus token against every surface a control can sit on, in both themes; the offset
# is asserted too, because at 0 the outline would cover the control's own edge and
# the surfaces below would stop being the right thing to measure.
#
# Nothing else can catch this. axe has no 2.4.13 rule (it ships no wcag22aaa rules at
# all) and measures text contrast only, and the render tests assert class names, not
# values.
#
# Every value is read from the SHIPPED stylesheet, down through the primitive layer to
# the Tailwind palette shade it names, so a remap cannot pass this by moving a number
# the test does not read.
class TestFocusIndicatorContrast < Minitest::Test
  FOCUS_FLOOR = 3.0
  MIN_OUTLINE_PX = 2
  CSS = File.expand_path("../lib/generators/modelrails_ui/install/templates/modelrails_ui.css", __dir__)
  SURFACES = %w[surface surface-raised surface-overlay surface-sunken].freeze

  # Tailwind v4 default palette, for the shades the default primitives point these
  # tokens at. A remap onto a shade missing here fails loudly rather than guessing.
  TAILWIND = {
    "sky-300" => [0.828, 0.111, 230.318],
    "sky-800" => [0.443, 0.110, 240.790],
    "slate-50" => [0.984, 0.003, 247.858],
    "slate-100" => [0.968, 0.007, 247.896],
    "slate-800" => [0.279, 0.041, 260.031],
    "slate-900" => [0.208, 0.042, 265.755],
    "slate-950" => [0.129, 0.042, 264.695]
  }.freeze

  def css = @css ||= File.read(CSS)

  # Every block for a selector, joined in source order, so a later declaration wins
  # exactly as it does in the cascade.
  def declarations(selector)
    css.scan(/^#{Regexp.escape(selector)} \{.*?^\}/m).join("\n")
  end

  def declared(name, selector)
    value = declarations(selector).scan(/^\s*#{Regexp.escape(name)}:\s*([^;]+);/).flatten.last

    refute_nil value, "#{name} is not declared in any #{selector} block of the shipped stylesheet"
    value.strip
  end

  def resolve(raw)
    case raw
    when /\Aoklch\(\s*([\d.]+)%\s+([\d.]+)\s+([\d.]+)\s*\)\z/
      [$1.to_f / 100.0, $2.to_f, $3.to_f]
    when /\Avar\((--(?:primary|neutral)-\d+)\)\z/
      primitive = $1
      shade = declared(primitive, ":root")[/\Avar\(--color-([a-z]+-\d+)\)\z/, 1]

      TAILWIND.fetch(shade) do
        flunk "#{primitive} points at #{shade.inspect}; add its Tailwind v4 OKLCH triple to TAILWIND " \
              "so the ratio is computed against what actually ships"
      end
    else
      flunk "unrecognised token value #{raw.inspect}"
    end
  end

  def token(name, theme)
    resolve(declared("--color-#{name}", (theme == :dark) ? ".dark" : ":root"))
  end

  def focus_ring_rule
    rule = css[/^@utility focus-ring \{.*?^\}/m]

    refute_nil rule, "the shipped stylesheet no longer defines @utility focus-ring"
    rule
  end

  def oklch_luminance(l, c, h)
    hr = h * Math::PI / 180.0
    a = c * Math.cos(hr)
    b = c * Math.sin(hr)
    l_ = (l + 0.3963377774 * a + 0.2158037573 * b)**3
    m_ = (l - 0.1055613458 * a - 0.0638541728 * b)**3
    s_ = (l - 0.0894841775 * a - 1.2914855480 * b)**3
    r = 4.0767416621 * l_ - 3.3077115913 * m_ + 0.2309699292 * s_
    g = -1.2684380046 * l_ + 2.6097574011 * m_ - 0.3413193965 * s_
    bl = -0.0041960863 * l_ - 0.7034186147 * m_ + 1.7076147010 * s_
    rr, gg, bb = [r, g, bl].map { |x| x.clamp(0.0, 1.0) }
    0.2126 * rr + 0.7152 * gg + 0.0722 * bb
  end

  def contrast(one, two)
    y1 = oklch_luminance(*one)
    y2 = oklch_luminance(*two)
    ([y1, y2].max + 0.05) / ([y1, y2].min + 0.05)
  end

  def test_the_focus_ring_is_a_solid_offset_outline_in_the_focus_token
    outline = focus_ring_rule[/^\s*outline:\s*([^;]+);/, 1]

    refute_nil outline, "focus-ring no longer sets an outline"
    width, style, color = outline.split(/\s+/, 3)

    assert_operator width.to_f, :>=, MIN_OUTLINE_PX,
      "focus-ring outline is #{width}; 2.4.13 needs at least a #{MIN_OUTLINE_PX}px perimeter"
    assert_equal "solid", style, "a dashed or dotted ring paints too little of the perimeter to be measured this way"
    assert_equal "var(--color-interactive-focus)", color
    assert_operator focus_ring_rule[/outline-offset:\s*([\d.]+)px/, 1].to_f, :>, 0,
      "without an offset the ring covers the control's own edge, and the surface ratios below stop applying"
  end

  def test_the_focus_ring_clears_three_to_one_on_every_surface_in_both_themes
    failures = %i[light dark].flat_map do |theme|
      focus = token("interactive-focus", theme)
      SURFACES.filter_map do |surface|
        ratio = contrast(focus, token(surface, theme))
        next if ratio >= FOCUS_FLOOR

        format("%s interactive-focus on %s: %.2f:1", theme, surface, ratio)
      end
    end

    assert_empty failures, <<~MSG
      The focus ring is under #{FOCUS_FLOOR}:1 against the ground it is drawn over, so a
      keyboard user cannot reliably see where focus is (WCAG 2.4.13, 1.4.11):

        #{failures.join("\n  ")}
    MSG
  end
end
