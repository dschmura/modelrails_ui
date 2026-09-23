# frozen_string_literal: true

require "test_helper"

# A signal chip's BORDER is the only thing that gives it a boundary.
#
# The fill cannot do it. A tinted chip's surface measures ~1.06:1 against the
# page, and it cannot darken: the tone's text sits on it at 7:1, and the
# darkest fill that still holds that reaches only 1.09-1.29:1 against the page.
# AAA text and a visible fill are mutually exclusive on a chip, so if the
# border does not carry the edge, nothing does (#257).
#
# Every value is read from the SHIPPED stylesheet rather than restated here, so
# a remap cannot pass this by moving a number the test does not read.
#
# Nothing else can catch this. axe measures TEXT contrast only — a border never
# enters an audit — and the render tests assert class names, not values.
class TestSignalBorderContrast < Minitest::Test
  NON_TEXT_FLOOR = 3.0
  STYLESHEET = File.expand_path(
    "../lib/generators/modelrails_ui/install/templates/modelrails_ui.css", __dir__
  )
  TONES = %w[danger warning success info].freeze

  # The WORST ground in each theme, which is what the floor has to clear:
  # a light border sits on `surface` (the darker of the two light grounds),
  # a dark one on `surface-raised` (the lighter of the two dark grounds).
  LIGHT_GROUND = {name: "surface (slate-50)", oklch: [0.984, 0.003, 247.858]}.freeze
  DARK_GROUND = {name: "surface-raised (slate-800)", oklch: [0.279, 0.041, 260.031]}.freeze

  def stylesheet = @stylesheet ||= File.read(STYLESHEET)

  # The file declares each token twice — light block first, dark second.
  def border_values(tone)
    stylesheet.scan(/--color-#{tone}-border:\s*oklch\(([\d.]+)%\s+([\d.]+)\s+([\d.]+)\)/)
      .map { |l, c, h| [l.to_f / 100.0, c.to_f, h.to_f] }
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

  # POSITIVE CONTROL — every assertion below is a loop over what the regex
  # found. A regex that matches nothing asserts nothing and passes.
  def test_it_reads_both_themes_for_every_tone
    TONES.each do |tone|
      assert_equal 2, border_values(tone).size,
        "expected a light and a dark --color-#{tone}-border in the shipped stylesheet; " \
        "found #{border_values(tone).size}. The scan has stopped reading the tokens."
    end
  end

  def test_every_signal_border_clears_the_non_text_floor
    failures = TONES.flat_map do |tone|
      light, dark = border_values(tone)
      [["light", tone, light, LIGHT_GROUND], ["dark", tone, dark, DARK_GROUND]]
        .filter_map do |theme, name, value, ground|
          ratio = contrast(value, ground[:oklch])
          next if ratio >= NON_TEXT_FLOOR

          format("%s %s-border: %.2f:1 against %s", theme, name, ratio, ground[:name])
        end
    end

    assert_empty failures, <<~MSG
      These signal borders are under the #{NON_TEXT_FLOOR}:1 non-text floor, so the chips they
      outline have no perceivable boundary — and the fill cannot rescue them,
      because it has AAA text sitting on it:

        #{failures.join("\n  ")}
    MSG
  end
end
