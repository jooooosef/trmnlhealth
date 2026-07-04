import Foundation

enum SyncError: LocalizedError {
    case healthDataUnavailable
    case noServerConfigured
    case noHealthData

    var errorDescription: String? {
        switch self {
        case .healthDataUnavailable:
            "Health data is not available on this device"
        case .noServerConfigured:
            "No server URL configured — add one in Settings"
        case .noHealthData:
            "No Health data was readable — check permissions in the Health app"
        }
    }
}

/// Orchestrates one sync: read today's metrics, build the payload, POST it.
/// Shared by the manual sync UI now and the background delivery
/// coordinator in a future version.
final class SyncEngine {
    private let reader: any HealthDataReader
    private let client: any WebhookClient
    private let settings: SettingsStore

    init(reader: any HealthDataReader, client: any WebhookClient, settings: SettingsStore) {
        self.reader = reader
        self.client = client
        self.settings = settings
    }

    @discardableResult
    func sync(day: Date = .now, generatedAt: Date = .now) async throws -> DailyMetrics {
        guard let url = settings.webhookURL else {
            throw SyncError.noServerConfigured
        }
        let metrics = try await reader.dailyMetrics(for: day)
        // An all-empty read means something systemic (permissions wiped,
        // store locked) — POSTing it would wipe the display's last good
        // data with dashes, so fail loudly instead.
        guard metrics.hasAnyData else {
            throw SyncError.noHealthData
        }
        let payload = PayloadBuilder.build(from: metrics, generatedAt: generatedAt, timeZone: .current)
        let body = try PayloadBuilder.encode(payload)
        try await client.post(body, to: url)
        return metrics
    }
}
