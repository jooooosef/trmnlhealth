import Foundation

/// One day of aggregated health metrics in domain units.
/// Every metric is optional: absence means the data type had no samples
/// or the user denied read access to it.
struct DailyMetrics: Equatable {
    var day: Date
    var steps: Int?
    var distanceKm: Double?
    var activeEnergyKcal: Double?
    var exerciseMinutes: Int?
    var restingHeartRateBpm: Int?
    var weightKg: Double?
    var sleep: SleepSummary?
}

/// Aggregated sleep for the night ending on `DailyMetrics.day`.
struct SleepSummary: Equatable {
    var start: Date?
    var end: Date?
    var totalMinutes: Int?
    var inBedMinutes: Int?
    var deepMinutes: Int?
    var remMinutes: Int?
    var coreMinutes: Int?
    var awakeMinutes: Int?
}
