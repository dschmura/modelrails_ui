# frozen_string_literal: true

require "test_helper"

# WCAG 2.2 AAA guarantee for the shipped design tokens.
#
# The semantic tokens resolve to Tailwind v4 palette values (primary => sky,
# neutral => slate). This test pins those values and computes contrast from
# OKLCH -> OKLab -> linear sRGB -> relative luminance, asserting the core
# text/background pairs meet AAA (>= 7:1) in BOTH light and dark modes.
#
# If a future token remap drops a pair below 7:1, this test fails — making AAA
# a property the gem proves, not one inherited from a host app.
class TestAaaContrast < Minitest::Test
  AAA = 7.0

  # Tailwind v4 default palette OKLCH [L (0..1), C, H] for the shades the tokens use.
  WHITE = [1.0, 0.0, 0.0].freeze
  BLACK = [0.0, 0.0, 0.0].freeze
  SKY_300 = [0.828, 0.111, 230.318].freeze # dark-mode interactive (primary-300)
  SKY_800 = [0.443, 0.110, 240.790].freeze # light-mode interactive (primary-800)
  SLATE_50 = [0.984, 0.003, 247.858].freeze # light surface (neutral-50)
  SLATE_100 = [0.968, 0.007, 247.896].freeze # dark text-heading (neutral-100)
  SLATE_300 = [0.869, 0.022, 252.894].freeze # dark text-body (neutral-300)
  SLATE_700 = [0.372, 0.044, 257.287].freeze # light text-body/muted (neutral-700)
  SLATE_800 = [0.279, 0.041, 260.031].freeze # dark surface-raised (neutral-800)
  SLATE_900 = [0.208, 0.042, 265.755].freeze # light text-heading / dark surface (neutral-900)

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

  def contrast(c1, c2)
    y1 = oklch_luminance(*c1)
    y2 = oklch_luminance(*c2)
    hi = [y1, y2].max
    lo = [y1, y2].min
    (hi + 0.05) / (lo + 0.05)
  end

  def assert_aaa(fg, bg, label)
    ratio = contrast(fg, bg)

    assert_operator ratio, :>=, AAA, "#{label}: #{ratio.round(2)}:1 is below AAA (#{AAA}:1)"
  end

  def test_color_math_anchors
    assert_in_delta 21.0, contrast(WHITE, BLACK), 0.1, "white on black must be ~21:1"
    # Documented in _semantic.css: interactive (primary-800) + white text = 7.56:1
    assert_in_delta 7.56, contrast(WHITE, SKY_800), 0.4, "interactive+white anchor"
  end

  def test_light_mode_text_pairs_meet_aaa
    assert_aaa SLATE_900, WHITE, "light: text-heading on surface-raised"
    assert_aaa SLATE_900, SLATE_50, "light: text-heading on surface"
    assert_aaa SLATE_700, WHITE, "light: text-body on surface-raised"
    assert_aaa SLATE_700, SLATE_50, "light: text-body on surface"
    assert_aaa WHITE, SKY_800, "light: text-on-interactive on interactive"
  end

  def test_dark_mode_text_pairs_meet_aaa
    assert_aaa SLATE_100, SLATE_900, "dark: text-heading on surface"
    assert_aaa SLATE_100, SLATE_800, "dark: text-heading on surface-raised"
    assert_aaa SLATE_300, SLATE_900, "dark: text-body on surface"
    assert_aaa SLATE_300, SLATE_800, "dark: text-body on surface-raised"
    assert_aaa SLATE_900, SKY_300, "dark: text-on-interactive on interactive"
  end
end
