import Foundation

/// The character of a single flush, as numbers.
///
/// `FlushTimeline` and `FlushAudio` were both written against hard-coded constants,
/// which is exactly right for an app with one toilet in it. A profile lifts those
/// constants into a value so a fixture can own its own surge, its own swirl and its
/// own voice, without either of those files learning what a fixture is.
///
/// `.standard` reproduces the original numbers exactly, so swapping the constants
/// for a profile changes nothing until something hands over a different one.
struct FlushProfile: Equatable {

    // MARK: - Shape of the flush

    /// How long a flush takes, start to settled, in seconds.
    var duration: Double

    /// Water level in the bowl at rest. 0 = empty, 1 = brimming.
    var restingLevel: Double

    /// How high the surge climbs before the bowl lets go.
    var surgePeak: Double

    /// Degrees per second at full churn.
    var spinPeak: Double

    /// Sideways travel of the whole fixture, in points.
    var rumbleScale: Double

    /// Chop on the water's surface.
    var chop: Double

    // MARK: - Voice

    /// The handle bottoming out.
    var clunkFrequency: Double

    /// The roar sweeps between these as the bowl empties.
    var roarFrom: Double
    var roarTo: Double

    /// The low body underneath the roar.
    var bodyFrequency: Double

    /// The uneven glugging: centre frequency, and how far it wanders.
    var gurgleCentre: Double
    var gurgleSwing: Double

    /// The tank refilling, rising in pitch as it fills.
    var hissFrom: Double
    var hissTo: Double

    /// The float valve shutting off at the end.
    var valveFrequency: Double

    /// The original toilet, to the number. Changing anything here changes the app
    /// that already shipped, so don't — add a new profile instead.
    static let standard = FlushProfile(
        duration: 3.6,
        restingLevel: 0.52,
        surgePeak: 0.95,
        spinPeak: 1_400,
        rumbleScale: 1.7,
        chop: 0.014,
        clunkFrequency: 94,
        roarFrom: 1_250,
        roarTo: 370,
        bodyFrequency: 165,
        gurgleCentre: 620,
        gurgleSwing: 250,
        hissFrom: 2_150,
        hissTo: 3_100,
        valveFrequency: 118
    )
}
