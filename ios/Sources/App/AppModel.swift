import Foundation
import Observation

@Observable
final class AppModel {
    private(set) var todayMetrics: DailyMetrics?
    private(set) var syncStatus: SyncStatus = .idle

    let settings: SettingsStore
    private let reader: any HealthDataReader
    private let engine: SyncEngine

    var isHealthDataAvailable: Bool {
        reader.isAvailable
    }

    init(reader: any HealthDataReader, engine: SyncEngine, settings: SettingsStore) {
        self.reader = reader
        self.engine = engine
        self.settings = settings
    }

    /// Reads today's metrics for display without POSTing anything.
    func refreshPreview() async {
        todayMetrics = try? await reader.dailyMetrics(for: .now)
    }

    func syncNow() async {
        guard !syncStatus.isSyncing else { return }
        syncStatus = .syncing
        do {
            todayMetrics = try await engine.sync()
            syncStatus = .success(.now)
        } catch {
            syncStatus = .failure(error.localizedDescription)
        }
    }

    func completeOnboarding() async {
        try? await reader.requestAuthorization()
        settings.hasCompletedOnboarding = true
        await refreshPreview()
    }
}
