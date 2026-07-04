import Foundation
import Testing
@testable import HealthForTRMNL

/// Tests the exact method the Sync Now button invokes, through the real
/// AppModel and SyncEngine, with only the device boundaries faked.
struct AppModelTests {
    private func makeModel(
        urlString: String?,
        client: SpyWebhookClient = SpyWebhookClient()
    ) -> (AppModel, SpyWebhookClient) {
        let reader = FakeHealthDataReader(metricsToReturn: TestFixtures.exampleMetrics())
        let settings = TestFixtures.settings(urlString: urlString)
        let engine = SyncEngine(reader: reader, client: client, settings: settings)
        return (AppModel(reader: reader, engine: engine, settings: settings), client)
    }

    @Test
    func syncNowPostsToConfiguredAddressAndReportsSuccess() async throws {
        // 192.0.2.x is an RFC 5737 documentation address: guaranteed
        // unroutable. The URL is only compared as a string here; the spy
        // client performs no networking at all.
        let url = "http://192.0.2.50:4567/api/custom_plugins/my-uuid"
        let (model, client) = makeModel(urlString: url)

        await model.syncNow()

        #expect(client.posts.count == 1)
        #expect(client.posts.first?.url.absoluteString == url)
        guard case .success = model.syncStatus else {
            Issue.record("expected success, got \(model.syncStatus)")
            return
        }
        #expect(model.todayMetrics == TestFixtures.exampleMetrics())
    }

    @Test
    func syncNowWithoutServerFailsWithoutPosting() async {
        let (model, client) = makeModel(urlString: nil)

        await model.syncNow()

        #expect(client.posts.isEmpty)
        guard case .failure(let message) = model.syncStatus else {
            Issue.record("expected failure, got \(model.syncStatus)")
            return
        }
        #expect(message.contains("No server URL"))
    }

    @Test
    func syncNowSurfacesServerErrorsInStatus() async {
        let client = SpyWebhookClient()
        client.errorToThrow = WebhookResponseError(statusCode: 500)
        let (model, _) = makeModel(urlString: "http://localhost:4567/api/custom_plugins/x", client: client)

        await model.syncNow()

        guard case .failure(let message) = model.syncStatus else {
            Issue.record("expected failure, got \(model.syncStatus)")
            return
        }
        #expect(message.contains("500"))
    }
}
