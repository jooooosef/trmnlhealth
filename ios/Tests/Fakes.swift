import Foundation
@testable import TrmnlHealth

final class FakeHealthDataReader: HealthDataReader {
    var isAvailable = true
    var metricsToReturn: DailyMetrics
    var errorToThrow: Error?
    private(set) var authorizationRequests = 0

    init(metricsToReturn: DailyMetrics) {
        self.metricsToReturn = metricsToReturn
    }

    func requestAuthorization() async throws {
        authorizationRequests += 1
    }

    func dailyMetrics(for day: Date) async throws -> DailyMetrics {
        if let errorToThrow {
            throw errorToThrow
        }
        return metricsToReturn
    }
}

final class SpyWebhookClient: WebhookClient {
    private(set) var posts: [(body: Data, url: URL)] = []
    var errorToThrow: Error?

    func post(_ body: Data, to url: URL) async throws {
        if let errorToThrow {
            throw errorToThrow
        }
        posts.append((body, url))
    }
}

enum TestFixtures {
    /// Domain metrics matching docs/examples/payload.example.json exactly.
    static func exampleMetrics() -> DailyMetrics {
        let berlin = TimeZone(identifier: "Europe/Berlin")!
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = berlin

        let day = calendar.date(from: DateComponents(year: 2026, month: 7, day: 4))!
        let sleepStart = calendar.date(from: DateComponents(year: 2026, month: 7, day: 3, hour: 23, minute: 12))!
        let sleepEnd = calendar.date(from: DateComponents(year: 2026, month: 7, day: 4, hour: 7, minute: 5))!

        return DailyMetrics(
            day: day,
            steps: 8342,
            distanceKm: 6.4,
            activeEnergyKcal: 512,
            exerciseMinutes: 32,
            restingHeartRateBpm: 58,
            weightKg: 78.4,
            sleep: SleepSummary(
                start: sleepStart,
                end: sleepEnd,
                totalMinutes: 430,
                inBedMinutes: 470,
                deepMinutes: 62,
                remMinutes: 98,
                coreMinutes: 270,
                awakeMinutes: 12
            )
        )
    }

    static let generatedAt = ISO8601DateFormatter().date(from: "2026-07-04T18:30:00Z")!
    static let berlin = TimeZone(identifier: "Europe/Berlin")!

    static func settings(urlString: String?) -> SettingsStore {
        let defaults = UserDefaults(suiteName: "tests-\(UUID().uuidString)")!
        let settings = SettingsStore(defaults: defaults)
        if let urlString {
            settings.webhookURLString = urlString
        }
        return settings
    }

    final class BundleToken {}

    static func resourceData(_ name: String, extension ext: String) throws -> Data {
        let bundle = Bundle(for: BundleToken.self)
        guard let url = bundle.url(forResource: name, withExtension: ext) else {
            throw CocoaError(.fileNoSuchFile)
        }
        return try Data(contentsOf: url)
    }
}
