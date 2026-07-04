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
        await requestNewPermissionsIfNeeded()
        todayMetrics = try? await reader.dailyMetrics(for: .now)
    }

    func syncNow() async {
        guard !syncStatus.isSyncing else { return }
        syncStatus = .syncing
        await requestNewPermissionsIfNeeded()
        do {
            todayMetrics = try await engine.sync()
            syncStatus = .success(.now)
        } catch {
            syncStatus = .failure(error.localizedDescription)
        }
    }

    /// No-op unless an app update added read types the user has never
    /// been asked about: HealthKit shows a sheet only for types still in
    /// the not-determined state, and queries on those THROW rather than
    /// return empty. Asking again for already-decided types is silent.
    /// First-run authorization stays in completeOnboarding().
    private func requestNewPermissionsIfNeeded() async {
        guard settings.hasCompletedOnboarding else { return }
        try? await reader.requestAuthorization()
    }

    func completeOnboarding() async {
        try? await reader.requestAuthorization()
        settings.hasCompletedOnboarding = true
        await refreshPreview()
    }
}
