import Foundation

/// Boundary protocol isolating HealthKit so the rest of the app is testable
/// with fakes (HealthKit itself offers no mocking hooks).
protocol HealthDataReader {
    var isAvailable: Bool { get }
    func requestAuthorization() async throws
    func dailyMetrics(for day: Date) async throws -> DailyMetrics
}
