import Foundation
import Testing
@testable import HealthForTRMNL

struct SyncEngineTests {
    @Test
    func happyPathPostsExactlyOnce() async throws {
        let reader = FakeHealthDataReader(metricsToReturn: TestFixtures.exampleMetrics())
        let client = SpyWebhookClient()
        let settings = TestFixtures.settings(urlString: "http://localhost:4567/api/custom_plugins/abc123")
        let engine = SyncEngine(reader: reader, client: client, settings: settings)

        try await engine.sync()

        #expect(client.posts.count == 1)
        let post = try #require(client.posts.first)
        #expect(post.url.absoluteString == "http://localhost:4567/api/custom_plugins/abc123")

        let body = try JSONSerialization.jsonObject(with: post.body) as? [String: Any]
        let variables = body?["merge_variables"] as? [String: Any]
        #expect(variables?["schema_version"] as? Int == 1)
        #expect(variables?["steps"] as? Int == 8342)
    }

    @Test
    func missingServerURLThrowsWithoutReadingOrPosting() async throws {
        let reader = FakeHealthDataReader(metricsToReturn: TestFixtures.exampleMetrics())
        let client = SpyWebhookClient()
        let settings = TestFixtures.settings(urlString: nil)
        let engine = SyncEngine(reader: reader, client: client, settings: settings)

        await #expect(throws: SyncError.self) {
            try await engine.sync()
        }
        #expect(client.posts.isEmpty)
    }

    @Test
    func readerFailurePropagatesAndNothingIsPosted() async throws {
        let reader = FakeHealthDataReader(metricsToReturn: TestFixtures.exampleMetrics())
        reader.errorToThrow = CocoaError(.fileNoSuchFile)
        let client = SpyWebhookClient()
        let settings = TestFixtures.settings(urlString: "http://localhost:4567/api/custom_plugins/abc123")
        let engine = SyncEngine(reader: reader, client: client, settings: settings)

        await #expect(throws: Error.self) {
            try await engine.sync()
        }
        #expect(client.posts.isEmpty)
    }

    @Test
    func clientFailurePropagates() async throws {
        let reader = FakeHealthDataReader(metricsToReturn: TestFixtures.exampleMetrics())
        let client = SpyWebhookClient()
        client.errorToThrow = WebhookResponseError(statusCode: 500)
        let settings = TestFixtures.settings(urlString: "http://localhost:4567/api/custom_plugins/abc123")
        let engine = SyncEngine(reader: reader, client: client, settings: settings)

        await #expect(throws: WebhookResponseError.self) {
            try await engine.sync()
        }
    }

    @Test
    func invalidURLStringMeansNoServerConfigured() {
        let settings = TestFixtures.settings(urlString: "not a url")
        #expect(settings.webhookURL == nil)
    }
}
