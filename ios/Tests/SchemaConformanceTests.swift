import Foundation
import JSONSchema
import Testing
@testable import HealthForTRMNL

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
        metrics.standHours = nil
        metrics.restingHeartRateBpm = nil
        metrics.hrvMs = nil
        metrics.vo2Max = nil
        metrics.weightKg = nil
        metrics.goals = nil
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

    /// iPhone-only users have a Move goal but no Exercise/Stand goals
    /// (those require an Apple Watch) — a partial goals object is valid.
    @Test
    func moveOnlyGoalsValidateAgainstSchema() throws {
        var metrics = TestFixtures.exampleMetrics()
        metrics.goals = ActivityGoals(moveKcal: 600)
        metrics.standHours = nil
        metrics.hrvMs = nil

        let payload = PayloadBuilder.build(
            from: metrics,
            generatedAt: TestFixtures.generatedAt,
            timeZone: TestFixtures.berlin
        )
        let encoded = try PayloadBuilder.encode(payload)

        let result = try loadSchema().validate(instance: String(decoding: encoded, as: UTF8.self))
        #expect(result.isValid, "\(String(describing: result.errors))")
    }

    @Test
    func schemaRejectsUnknownGoalKeys() throws {
        let broken = #"{"merge_variables": {"schema_version": 1, "date": "2026-07-04", "goals": {"step_goal": 10000}}}"#
        let result = try loadSchema().validate(instance: broken)
        #expect(!result.isValid, "goals is additionalProperties: false too")
    }
}
