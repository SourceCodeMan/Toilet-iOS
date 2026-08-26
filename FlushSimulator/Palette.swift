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
