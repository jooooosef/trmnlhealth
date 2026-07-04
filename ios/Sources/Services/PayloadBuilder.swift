import Foundation

/// Pure transformation from domain metrics to the wire payload.
/// This is the app-side half of the schema contract and the target of the
/// golden and schema-conformance tests.
enum PayloadBuilder {
    static func build(
        from metrics: DailyMetrics,
        generatedAt: Date,
        timeZone: TimeZone
    ) -> HealthPayload {
        let dayFormatter = Self.formatter("yyyy-MM-dd", timeZone: timeZone)
        let clockFormatter = Self.formatter("HH:mm", timeZone: timeZone)

        var sleep: HealthPayload.Sleep?
        if let summary = metrics.sleep {
            sleep = HealthPayload.Sleep(
                start: summary.start.map(clockFormatter.string(from:)),
                end: summary.end.map(clockFormatter.string(from:)),
                totalMinutes: summary.totalMinutes,
                inBedMinutes: summary.inBedMinutes,
                deepMinutes: summary.deepMinutes,
                remMinutes: summary.remMinutes,
                coreMinutes: summary.coreMinutes,
                awakeMinutes: summary.awakeMinutes
            )
        }

        let variables = HealthPayload.MergeVariables(
            date: dayFormatter.string(from: metrics.day),
            generatedAt: Self.iso8601.string(from: generatedAt),
            timezone: timeZone.identifier,
            steps: metrics.steps,
            distanceKm: metrics.distanceKm,
            activeEnergyKcal: metrics.activeEnergyKcal,
            exerciseMinutes: metrics.exerciseMinutes,
            restingHeartRateBpm: metrics.restingHeartRateBpm,
            weightKg: metrics.weightKg,
            sleep: sleep
        )
        return HealthPayload(mergeVariables: variables)
    }

    static func encode(_ payload: HealthPayload) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(payload)
    }

    // MARK: - Formatters

    private static let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }()

    private static func formatter(_ format: String, timeZone: TimeZone) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = format
        formatter.timeZone = timeZone
        return formatter
    }
}
