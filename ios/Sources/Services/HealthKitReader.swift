import Foundation
import HealthKit

final class HealthKitReader: HealthDataReader {
    private let store = HKHealthStore()

    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    private var readTypes: Set<HKObjectType> {
        [
            HKQuantityType(.stepCount),
            HKQuantityType(.distanceWalkingRunning),
            HKQuantityType(.activeEnergyBurned),
            HKQuantityType(.appleExerciseTime),
            HKQuantityType(.restingHeartRate),
            HKQuantityType(.bodyMass),
            HKCategoryType(.sleepAnalysis),
        ]
    }

    func requestAuthorization() async throws {
        try await store.requestAuthorization(toShare: [], read: readTypes)
    }

    func dailyMetrics(for day: Date) async throws -> DailyMetrics {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: day)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? day

        var metrics = DailyMetrics(day: startOfDay)
        metrics.steps = try await sum(.stepCount, unit: .count(), from: startOfDay, to: endOfDay).map { Int($0.rounded()) }
        metrics.distanceKm = try await sum(.distanceWalkingRunning, unit: .meter(), from: startOfDay, to: endOfDay)
            .map { ($0 / 100).rounded() / 10 }
        metrics.activeEnergyKcal = try await sum(.activeEnergyBurned, unit: .kilocalorie(), from: startOfDay, to: endOfDay)
            .map { $0.rounded() }
        metrics.exerciseMinutes = try await sum(.appleExerciseTime, unit: .minute(), from: startOfDay, to: endOfDay)
            .map { Int($0.rounded()) }
        metrics.restingHeartRateBpm = try await averageRestingHeartRate(from: startOfDay, to: endOfDay)
        metrics.weightKg = try await latestWeightKg()
        metrics.sleep = try await sleepSummary(nightEnding: startOfDay)
        return metrics
    }

    // MARK: - Queries

    private func sum(
        _ identifier: HKQuantityTypeIdentifier,
        unit: HKUnit,
        from start: Date,
        to end: Date
    ) async throws -> Double? {
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
        let descriptor = HKStatisticsQueryDescriptor(
            predicate: .quantitySample(type: HKQuantityType(identifier), predicate: predicate),
            options: .cumulativeSum
        )
        return try await descriptor.result(for: store)?.sumQuantity()?.doubleValue(for: unit)
    }

    private func averageRestingHeartRate(from start: Date, to end: Date) async throws -> Int? {
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
        let descriptor = HKStatisticsQueryDescriptor(
            predicate: .quantitySample(type: HKQuantityType(.restingHeartRate), predicate: predicate),
            options: .discreteAverage
        )
        let bpmUnit = HKUnit.count().unitDivided(by: .minute())
        let average = try await descriptor.result(for: store)?
            .averageQuantity()?
            .doubleValue(for: bpmUnit)
        return average.map { Int($0.rounded()) }
    }

    private func latestWeightKg() async throws -> Double? {
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.quantitySample(type: HKQuantityType(.bodyMass))],
            sortDescriptors: [SortDescriptor(\.endDate, order: .reverse)],
            limit: 1
        )
        return try await descriptor.result(for: store).first
            .map { ($0.quantity.doubleValue(for: .gramUnit(with: .kilo)) * 10).rounded() / 10 }
    }

    /// Collects sleep samples in a window around the night ending on the
    /// given day (noon before to noon of the day) and aggregates stages.
    private func sleepSummary(nightEnding startOfDay: Date) async throws -> SleepSummary? {
        let windowStart = startOfDay.addingTimeInterval(-12 * 3600)
        let windowEnd = startOfDay.addingTimeInterval(12 * 3600)
        let predicate = HKQuery.predicateForSamples(withStart: windowStart, end: windowEnd)
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.categorySample(type: HKCategoryType(.sleepAnalysis), predicate: predicate)],
            sortDescriptors: [SortDescriptor(\.startDate)],
            limit: nil
        )
        let samples = try await descriptor.result(for: store)
        guard !samples.isEmpty else { return nil }

        var stageSeconds: [HKCategoryValueSleepAnalysis: TimeInterval] = [:]
        var sleepStart: Date?
        var sleepEnd: Date?

        for sample in samples {
            guard let stage = HKCategoryValueSleepAnalysis(rawValue: sample.value) else { continue }
            stageSeconds[stage, default: 0] += sample.endDate.timeIntervalSince(sample.startDate)
            if stage != .inBed, stage != .awake {
                sleepStart = min(sleepStart ?? sample.startDate, sample.startDate)
                sleepEnd = max(sleepEnd ?? sample.endDate, sample.endDate)
            }
        }

        let asleepStages: [HKCategoryValueSleepAnalysis] = [.asleepUnspecified, .asleepCore, .asleepDeep, .asleepREM]
        let totalSeconds = asleepStages.reduce(0) { $0 + (stageSeconds[$1] ?? 0) }
        guard totalSeconds > 0 else { return nil }

        func minutes(_ stage: HKCategoryValueSleepAnalysis) -> Int? {
            stageSeconds[stage].map { Int(($0 / 60).rounded()) }
        }

        return SleepSummary(
            start: sleepStart,
            end: sleepEnd,
            totalMinutes: Int((totalSeconds / 60).rounded()),
            inBedMinutes: minutes(.inBed),
            deepMinutes: minutes(.asleepDeep),
            remMinutes: minutes(.asleepREM),
            coreMinutes: minutes(.asleepCore),
            awakeMinutes: minutes(.awake)
        )
    }
}
