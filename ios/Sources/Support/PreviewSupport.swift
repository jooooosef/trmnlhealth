#if DEBUG
import Foundation

/// Stub services so SwiftUI previews work without HealthKit or a network.
struct PreviewHealthDataReader: HealthDataReader {
    var isAvailable: Bool { true }

    func requestAuthorization() async throws {}

    func dailyMetrics(for day: Date) async throws -> DailyMetrics {
        DailyMetrics(
            day: Calendar.current.startOfDay(for: day),
            steps: 8342,
            distanceKm: 6.4,
            activeEnergyKcal: 512,
            exerciseMinutes: 32,
            standHours: 11,
            restingHeartRateBpm: 58,
            hrvMs: 46,
            vo2Max: 42.5,
            weightKg: 78.4,
            goals: ActivityGoals(moveKcal: 600, exerciseMinutes: 30, standHours: 12),
            sleep: SleepSummary(
                start: Calendar.current.date(byAdding: .hour, value: -9, to: day),
                end: Calendar.current.date(byAdding: .hour, value: -1, to: day),
                totalMinutes: 430,
                inBedMinutes: 470,
                deepMinutes: 62,
                remMinutes: 98,
                coreMinutes: 270,
                awakeMinutes: 12
            )
        )
    }
}

struct PreviewWebhookClient: WebhookClient {
    func post(_ body: Data, to url: URL) async throws {}
}

extension AppModel {
    static var preview: AppModel {
        let settings = SettingsStore(defaults: UserDefaults(suiteName: "preview") ?? .standard)
        settings.hasCompletedOnboarding = true
        settings.webhookURLString = "http://localhost:4567/api/custom_plugins/preview"
        let reader = PreviewHealthDataReader()
        let engine = SyncEngine(reader: reader, client: PreviewWebhookClient(), settings: settings)
        let model = AppModel(reader: reader, engine: engine, settings: settings)
        return model
    }
}
#endif
