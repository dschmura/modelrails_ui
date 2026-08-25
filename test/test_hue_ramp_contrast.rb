# frozen_string_literal: true

require "test_helper"

# AAA for the hue ramp, across every hue.
#
# The other contrast test pins fixed palette pairs. This one cannot: `bg-hue-initials`
# takes `--hue` from the caller, so the guarantee has to hold for all 360 hues, and the
# binding constraint is the WORST hue, not a representative one.
#
# Values are read out of the shipped stylesheet rather than restated here. A hardcoded
# copy would keep passing after someone edited the CSS, which is the failure this exists
# to prevent.
class TestHueRampContrast < Minitest::Test
  AAA = 7.0
  CSS = File.expand_path("../lib/generators/modelrails_ui/install/templates/modelrails_ui.css", __dir__)

  WHITE = [1.0, 0.0, 0.0].freeze
  SLATE_900 = [0.208, 0.042, 265.755].freeze # --neutral-900, the dark-mode on-color

  def css = @css ||= File.read(CSS)

  # Last definition wins for :root, first .dark block for dark — mirrors the cascade.
  def token(name, dark: false)
    scope = dark ? css[/^\.dark \{.*?^\}/m] : css[/^:root \{.*?#{Regexp.escape(name)}:.*?^\}/m]

    refute_nil scope, "no #{dark ? ".dark" : ":root"} block defining #{name}"
    m = scope[/#{Regexp.escape(name)}:\s*([0-9.]+)/, 1]

    refute_nil m, "#{name} not defined in #{dark ? ".dark" : ":root"}"
    Float(m)
  end

  # Resolve the DECLARED on-color rather than assuming it. Asserting AAA against a
  # hardcoded dark color would keep passing if the token reverted to white — the exact
  # regression this guards, and one a first draft of this test missed.
  ON_COLORS = {
    "oklch(100% 0 0)" => WHITE,
    "var(--neutral-900)" => SLATE_900
  }.freeze

  def on_color(dark: false)
    scope = dark ? css[/^\.dark \{.*?^\}/m] : css[/^:root \{.*?--color-text-on-hue-initials:.*?^\}/m]
    raw = scope[/--color-text-on-hue-initials:\s*([^;]+);/, 1].strip

    ON_COLORS.fetch(raw) do
      flunk "unrecognised on-color #{raw.inspect}; add it to ON_COLORS with its OKLCH triple " \
            "so the ratio below is computed against what actually ships"
    end
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

  def contrast(c1, c2)
    y1 = oklch_luminance(*c1)
    y2 = oklch_luminance(*c2)
    ([y1, y2].max + 0.05) / ([y1, y2].min + 0.05)
  end

  # True when the OKLCH triple falls outside sRGB. Matters because the contrast model
  # above clamps, while a browser gamut-MAPS — for an out-of-gamut color the two disagree,
  # so a ratio computed here is an approximation of what actually renders.
  def out_of_gamut?(l, c, h)
    hr = h * Math::PI / 180.0
    a = c * Math.cos(hr)
    b = c * Math.sin(hr)
    l_ = (l + 0.3963377774 * a + 0.2158037573 * b)**3
    m_ = (l - 0.1055613458 * a - 0.0638541728 * b)**3
    s_ = (l - 0.0894841775 * a - 1.2914855480 * b)**3
    r = 4.0767416621 * l_ - 3.3077115913 * m_ + 0.2309699292 * s_
    g = -1.2684380046 * l_ + 2.6097574011 * m_ - 0.3413193965 * s_
    bl = -0.0041960863 * l_ - 0.7034186147 * m_ + 1.7076147010 * s_
    [r, g, bl].any? { |x| x < -0.001 || x > 1.001 }
  end

  def worst_hue(l, c, on_color)
    (0..359).map { |h| [contrast([l, c, h], on_color), h] }.min
  end

  def test_light_mode_hue_initials_meet_aaa_at_every_hue
    l = token("--hue-initials-l")
    c = token("--hue-initials-c")
    ratio, hue = worst_hue(l, c, on_color)

    assert_operator ratio, :>=, AAA,
      "light hue-initials worst hue #{hue}: #{ratio.round(2)}:1 below AAA"
  end

  def test_dark_mode_hue_initials_meet_aaa_at_every_hue
    l = token("--hue-initials-l", dark: true)
    c = token("--hue-initials-c", dark: true)
    ratio, hue = worst_hue(l, c, on_color(dark: true))

    assert_operator ratio, :>=, AAA,
      "dark hue-initials worst hue #{hue}: #{ratio.round(2)}:1 below AAA"
  end

  # The point of the issue: the fill must actually change between themes. A dark-mode
  # value equal to the light one would pass the two tests above while leaving a fixed
  # dark disc beside a light-flipping sibling chip.
  def test_the_hue_fill_re_lights_in_dark_mode
    assert_operator token("--hue-initials-l", dark: true), :>, token("--hue-initials-l") + 0.2,
      "dark hue fill must be substantially lighter than light mode, not the same disc"
  end

  # White on the re-lit fill is the mistake this replaces. Both halves are checked: the
  # declared token must not be white, AND white must actually fail there — so neither a
  # token revert nor a fill that drifted dark again can pass unnoticed.
  def test_the_dark_on_color_is_dark_and_white_would_fail_there
    refute_equal WHITE, on_color(dark: true),
      "dark on-color reverted to white; the re-lit fill needs dark text"

    l = token("--hue-initials-l", dark: true)
    c = token("--hue-initials-c", dark: true)
    ratio, = worst_hue(l, c, WHITE)

    assert_operator ratio, :<, AAA,
      "dark fill is dark enough for white text — it did not re-light"
  end

  # The dark value is chosen to sit inside sRGB at every hue, so the ratio above is what
  # renders rather than an approximation of the browser's gamut mapping. The light value
  # predates this test and is NOT in gamut — recorded, not asserted, so this stays a
  # regression guard on the new value rather than a failing complaint about the old one.
  def test_the_dark_mode_hue_fill_is_in_gamut_at_every_hue
    l = token("--hue-initials-l", dark: true)
    c = token("--hue-initials-c", dark: true)
    outside = (0..359).count { |h| out_of_gamut?(l, c, h) }

    assert_equal 0, outside, "#{outside} hues fall outside sRGB; the AAA ratio is then only an estimate"
  end
end
