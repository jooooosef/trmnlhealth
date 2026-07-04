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
    var standHours: Int?
    var restingHeartRateBpm: Int?
    var hrvMs: Double?
    var vo2Max: Double?
    var weightKg: Double?
    var goals: ActivityGoals?
    var sleep: SleepSummary?

    /// True when at least one metric was readable. A sync refuses to
    /// POST an all-empty day (see SyncEngine).
    var hasAnyData: Bool {
        steps != nil || distanceKm != nil || activeEnergyKcal != nil
            || exerciseMinutes != nil || standHours != nil
            || restingHeartRateBpm != nil || hrvMs != nil || vo2Max != nil
            || weightKg != nil || goals != nil || sleep != nil
    }
}

/// The user's Activity ring goals from the Fitness app. A goal is nil when
/// it is not configured on the device (Exercise and Stand goals require an
/// Apple Watch; the Move goal is nil in minutes-based Move mode).
struct ActivityGoals: Equatable {
    var moveKcal: Double?
    var exerciseMinutes: Int?
    var standHours: Int?
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
