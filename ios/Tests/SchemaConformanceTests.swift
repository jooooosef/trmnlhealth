import Foundation
import JSONSchema
import Testing
@testable import TrmnlHealth

/// Validates the app's REAL encoder output against the same schema file
/// that CI validates the fixture against — the two halves of the contract
/// are tested against one source of truth.
struct SchemaConformanceTests {
    private func loadSchema() throws -> Schema {
        let data = try TestFixtures.resourceData("health-summary.v1.schema", extension: "json")
        return try Schema(instance: String(decoding: data, as: UTF8.self))
    }

    @Test
    func encoderOutputValidatesAgainstSchema() throws {
        let payload = PayloadBuilder.build(
            from: TestFixtures.exampleMetrics(),
            generatedAt: TestFixtures.generatedAt,
            timeZone: TestFixtures.berlin
        )
        let encoded = try PayloadBuilder.encode(payload)

        let result = try loadSchema().validate(instance: String(decoding: encoded, as: UTF8.self))
        #expect(result.isValid, "\(String(describing: result.errors))")
    }

    @Test
    func sparsePayloadValidatesAgainstSchema() throws {
        var metrics = TestFixtures.exampleMetrics()
        metrics.steps = nil
        metrics.distanceKm = nil
        metrics.activeEnergyKcal = nil
        metrics.exerciseMinutes = nil
        metrics.restingHeartRateBpm = nil
        metrics.weightKg = nil
        metrics.sleep = nil

        let payload = PayloadBuilder.build(
            from: metrics,
            generatedAt: TestFixtures.generatedAt,
            timeZone: TestFixtures.berlin
        )
        let encoded = try PayloadBuilder.encode(payload)

        let result = try loadSchema().validate(instance: String(decoding: encoded, as: UTF8.self))
        #expect(result.isValid, "an all-denied payload is still a valid contract instance")
    }

    @Test
    func schemaRejectsUnknownKeys() throws {
        let broken = #"{"merge_variables": {"schema_version": 1, "date": "2026-07-04", "setps": 1}}"#
        let result = try loadSchema().validate(instance: broken)
        #expect(!result.isValid, "additionalProperties: false must reject typo'd keys")
    }
}
