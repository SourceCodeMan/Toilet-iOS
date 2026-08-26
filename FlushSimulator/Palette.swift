import SwiftUI

/// Every colour in the app, in one value.
///
/// A golden flush swaps the whole thing out rather than tinting things one by one,
/// which is why this is a struct passed down the tree instead of a pile of constants.
struct Palette {
    var porcelainLight: Color
    var porcelainMid: Color
    var porcelainDark: Color
    var porcelainShadow: Color

    var chromeLight: Color
    var chromeMid: Color
    var chromeDark: Color

    var waterLight: Color
    var waterDark: Color
    var foam: Color

    var roomTop: Color
    var roomBottom: Color
    var tile: Color
    var ink: Color
    var accent: Color

    static func standard(_ scheme: ColorScheme) -> Palette {
        let dark = scheme == .dark
        return Palette(
            porcelainLight: Color(red: 1.00, green: 1.00, blue: 1.00),
            porcelainMid:   dark ? Color(red: 0.87, green: 0.89, blue: 0.92) : Color(red: 0.95, green: 0.96, blue: 0.98),
            porcelainDark:  dark ? Color(red: 0.72, green: 0.75, blue: 0.80) : Color(red: 0.84, green: 0.87, blue: 0.91),
            porcelainShadow: Color(red: 0.38, green: 0.44, blue: 0.53),
            chromeLight: Color(red: 0.98, green: 0.99, blue: 1.00),
            chromeMid:   Color(red: 0.76, green: 0.80, blue: 0.85),
            chromeDark:  Color(red: 0.42, green: 0.47, blue: 0.54),
            waterLight:  Color(red: 0.55, green: 0.82, blue: 0.95),
            waterDark:   Color(red: 0.11, green: 0.42, blue: 0.68),
            foam:        Color(red: 0.96, green: 0.99, blue: 1.00),
            roomTop:     dark ? Color(red: 0.09, green: 0.12, blue: 0.17) : Color(red: 0.83, green: 0.92, blue: 0.95),
            roomBottom:  dark ? Color(red: 0.05, green: 0.07, blue: 0.10) : Color(red: 0.68, green: 0.83, blue: 0.89),
            tile:        dark ? Color.white.opacity(0.05) : Color.white.opacity(0.35),
            ink:         dark ? Color(red: 0.90, green: 0.94, blue: 0.98) : Color(red: 0.10, green: 0.18, blue: 0.27),
            accent:      Color(red: 0.11, green: 0.52, blue: 0.78)
        )
    }

    /// Weathered pine, tin fittings, and water you would rather not look at.
    static func outhouse(_ scheme: ColorScheme) -> Palette {
        let dark = scheme == .dark
        return Palette(
            porcelainLight: Color(red: 0.72, green: 0.58, blue: 0.41),
            porcelainMid:   dark ? Color(red: 0.48, green: 0.37, blue: 0.25) : Color(red: 0.62, green: 0.48, blue: 0.33),
            porcelainDark:  dark ? Color(red: 0.31, green: 0.23, blue: 0.15) : Color(red: 0.44, green: 0.33, blue: 0.21),
            porcelainShadow: Color(red: 0.18, green: 0.13, blue: 0.08),
            chromeLight: Color(red: 0.78, green: 0.76, blue: 0.71),
            chromeMid:   Color(red: 0.55, green: 0.53, blue: 0.48),
            chromeDark:  Color(red: 0.31, green: 0.29, blue: 0.25),
            waterLight:  Color(red: 0.55, green: 0.52, blue: 0.30),
            waterDark:   Color(red: 0.27, green: 0.24, blue: 0.11),
            foam:        Color(red: 0.85, green: 0.83, blue: 0.68),
            roomTop:     dark ? Color(red: 0.13, green: 0.11, blue: 0.08) : Color(red: 0.79, green: 0.74, blue: 0.60),
            roomBottom:  dark ? Color(red: 0.07, green: 0.06, blue: 0.04) : Color(red: 0.62, green: 0.56, blue: 0.42),
            tile:        Color.black.opacity(dark ? 0.16 : 0.10),
            ink:         dark ? Color(red: 0.93, green: 0.89, blue: 0.79) : Color(red: 0.20, green: 0.15, blue: 0.08),
            accent:      Color(red: 0.53, green: 0.38, blue: 0.16)
        )
    }

    /// Cream porcelain, brass, and a great deal of self-regard.
    static func victorian(_ scheme: ColorScheme) -> Palette {
        let dark = scheme == .dark
        return Palette(
            porcelainLight: Color(red: 1.00, green: 0.99, blue: 0.95),
            porcelainMid:   dark ? Color(red: 0.88, green: 0.85, blue: 0.78) : Color(red: 0.96, green: 0.94, blue: 0.88),
            porcelainDark:  dark ? Color(red: 0.71, green: 0.67, blue: 0.58) : Color(red: 0.85, green: 0.81, blue: 0.72),
            porcelainShadow: Color(red: 0.36, green: 0.28, blue: 0.18),
            chromeLight: Color(red: 0.98, green: 0.91, blue: 0.71),
            chromeMid:   Color(red: 0.80, green: 0.65, blue: 0.33),
            chromeDark:  Color(red: 0.48, green: 0.35, blue: 0.12),
            waterLight:  Color(red: 0.63, green: 0.79, blue: 0.80),
            waterDark:   Color(red: 0.18, green: 0.38, blue: 0.44),
            foam:        Color(red: 0.97, green: 0.99, blue: 0.98),
            roomTop:     dark ? Color(red: 0.14, green: 0.10, blue: 0.12) : Color(red: 0.90, green: 0.84, blue: 0.82),
            roomBottom:  dark ? Color(red: 0.08, green: 0.06, blue: 0.07) : Color(red: 0.76, green: 0.68, blue: 0.68),
            tile:        Color.white.opacity(dark ? 0.05 : 0.28),
            ink:         dark ? Color(red: 0.95, green: 0.91, blue: 0.85) : Color(red: 0.24, green: 0.15, blue: 0.12),
            accent:      Color(red: 0.60, green: 0.42, blue: 0.14)
        )
    }

    /// Brushed steel, hard light, and no warmth anywhere.
    static func chrome(_ scheme: ColorScheme) -> Palette {
        let dark = scheme == .dark
        return Palette(
            porcelainLight: Color(red: 0.95, green: 0.96, blue: 0.97),
            porcelainMid:   dark ? Color(red: 0.63, green: 0.66, blue: 0.70) : Color(red: 0.80, green: 0.83, blue: 0.86),
            porcelainDark:  dark ? Color(red: 0.42, green: 0.45, blue: 0.49) : Color(red: 0.58, green: 0.62, blue: 0.66),
            porcelainShadow: Color(red: 0.16, green: 0.18, blue: 0.21),
            chromeLight: Color(red: 1.00, green: 1.00, blue: 1.00),
            chromeMid:   Color(red: 0.66, green: 0.70, blue: 0.75),
            chromeDark:  Color(red: 0.28, green: 0.31, blue: 0.35),
            waterLight:  Color(red: 0.72, green: 0.88, blue: 0.94),
            waterDark:   Color(red: 0.16, green: 0.36, blue: 0.50),
            foam:        Color(red: 1.00, green: 1.00, blue: 1.00),
            roomTop:     dark ? Color(red: 0.10, green: 0.11, blue: 0.13) : Color(red: 0.80, green: 0.84, blue: 0.87),
            roomBottom:  dark ? Color(red: 0.05, green: 0.06, blue: 0.07) : Color(red: 0.63, green: 0.68, blue: 0.73),
            tile:        Color.white.opacity(dark ? 0.07 : 0.40),
            ink:         dark ? Color(red: 0.92, green: 0.95, blue: 0.98) : Color(red: 0.12, green: 0.15, blue: 0.19),
            accent:      Color(red: 0.20, green: 0.58, blue: 0.78)
        )
    }

    /// Matte white composite under cold instrument light. No sky to speak of.
    static func orbital(_ scheme: ColorScheme) -> Palette {
        let dark = scheme == .dark
        return Palette(
            porcelainLight: Color(red: 0.97, green: 0.97, blue: 0.99),
            porcelainMid:   dark ? Color(red: 0.72, green: 0.73, blue: 0.80) : Color(red: 0.86, green: 0.87, blue: 0.92),
            porcelainDark:  dark ? Color(red: 0.48, green: 0.49, blue: 0.58) : Color(red: 0.63, green: 0.65, blue: 0.73),
            porcelainShadow: Color(red: 0.13, green: 0.13, blue: 0.20),
            chromeLight: Color(red: 0.88, green: 0.93, blue: 1.00),
            chromeMid:   Color(red: 0.55, green: 0.62, blue: 0.78),
            chromeDark:  Color(red: 0.25, green: 0.29, blue: 0.42),
            waterLight:  Color(red: 0.62, green: 0.95, blue: 0.90),
            waterDark:   Color(red: 0.09, green: 0.44, blue: 0.46),
            foam:        Color(red: 0.86, green: 1.00, blue: 0.98),
            roomTop:     Color(red: dark ? 0.03 : 0.08, green: dark ? 0.03 : 0.09, blue: dark ? 0.07 : 0.16),
            roomBottom:  Color(red: 0.01, green: 0.01, blue: 0.03),
            tile:        Color.white.opacity(0.05),
            ink:         Color(red: 0.90, green: 0.94, blue: 1.00),
            accent:      Color(red: 0.36, green: 0.78, blue: 0.86)
        )
    }

    /// One flush in twenty. Worth making a fuss about.
    static func golden(_ scheme: ColorScheme) -> Palette {
        let dark = scheme == .dark
        return Palette(
            porcelainLight: Color(red: 1.00, green: 0.97, blue: 0.84),
            porcelainMid:   Color(red: 0.98, green: 0.86, blue: 0.45),
            porcelainDark:  Color(red: 0.85, green: 0.65, blue: 0.16),
            porcelainShadow: Color(red: 0.45, green: 0.32, blue: 0.04),
            chromeLight: Color(red: 1.00, green: 0.98, blue: 0.88),
            chromeMid:   Color(red: 0.96, green: 0.82, blue: 0.38),
            chromeDark:  Color(red: 0.60, green: 0.44, blue: 0.06),
            waterLight:  Color(red: 1.00, green: 0.91, blue: 0.60),
            waterDark:   Color(red: 0.72, green: 0.49, blue: 0.05),
            foam:        Color(red: 1.00, green: 0.99, blue: 0.92),
            roomTop:     dark ? Color(red: 0.20, green: 0.15, blue: 0.03) : Color(red: 0.99, green: 0.93, blue: 0.72),
            roomBottom:  dark ? Color(red: 0.10, green: 0.07, blue: 0.01) : Color(red: 0.96, green: 0.82, blue: 0.48),
            tile:        Color.white.opacity(dark ? 0.06 : 0.30),
            ink:         dark ? Color(red: 1.00, green: 0.95, blue: 0.80) : Color(red: 0.30, green: 0.20, blue: 0.01),
            accent:      Color(red: 0.78, green: 0.55, blue: 0.06)
        )
    }
}
