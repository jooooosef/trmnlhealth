import Foundation
import Testing
@testable import TrmnlHealth

struct PayloadBuilderTests {
    @Test
    func encodedPayloadMatchesGoldenFixture() throws {
        let payload = PayloadBuilder.build(
            from: TestFixtures.exampleMetrics(),
            generatedAt: TestFixtures.generatedAt,
            timeZone: TestFixtures.berlin
        )
        let encoded = try PayloadBuilder.encode(payload)
        let fixture = try TestFixtures.resourceData("payload.example", extension: "json")

        let encodedObject = try JSONSerialization.jsonObject(with: encoded) as? NSDictionary
        let fixtureObject = try JSONSerialization.jsonObject(with: fixture) as? NSDictionary
        #expect(encodedObject == fixtureObject)
    }

    @Test
    func payloadStaysUnderWebhookSizeLimit() throws {
        let payload = PayloadBuilder.build(
            from: TestFixtures.exampleMetrics(),
            generatedAt: TestFixtures.generatedAt,
            timeZone: TestFixtures.berlin
        )
        let encoded = try PayloadBuilder.encode(payload)
        #expect(encoded.count <= 2048, "payload must fit trmnl.com's 2KB webhook limit")
    }

    @Test
    func missingMetricsAreOmittedNotNull() throws {
        var metrics = TestFixtures.exampleMetrics()
        metrics.steps = nil
        metrics.weightKg = nil
        metrics.sleep = nil

        let payload = PayloadBuilder.build(
            from: metrics,
            generatedAt: TestFixtures.generatedAt,
            timeZone: TestFixtures.berlin
        )
        let encoded = try PayloadBuilder.encode(payload)
        let json = String(decoding: encoded, as: UTF8.self)

        #expect(!json.contains("steps"))
        #expect(!json.contains("weight_kg"))
        #expect(!json.contains("sleep"))
        #expect(!json.contains("null"))
    }

    @Test
    func dateFieldsUseContractFormats() throws {
        let payload = PayloadBuilder.build(
            from: TestFixtures.exampleMetrics(),
            generatedAt: TestFixtures.generatedAt,
            timeZone: TestFixtures.berlin
        )

        #expect(payload.mergeVariables.date == "2026-07-04")
        #expect(payload.mergeVariables.generatedAt == "2026-07-04T18:30:00Z")
        #expect(payload.mergeVariables.timezone == "Europe/Berlin")
        #expect(payload.mergeVariables.sleep?.start == "23:12")
        #expect(payload.mergeVariables.sleep?.end == "07:05")
    }
}
