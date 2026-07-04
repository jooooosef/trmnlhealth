import Foundation

/// Wire model for the webhook POST body. The JSON shape is the versioned
/// contract in docs/schema/health-summary.v1.schema.json — additive-only
/// changes; a unit change is a rename.
struct HealthPayload: Encodable {
    var mergeVariables: MergeVariables

    enum CodingKeys: String, CodingKey {
        case mergeVariables = "merge_variables"
    }

    struct MergeVariables: Encodable {
        var schemaVersion = 1
        var date: String
        var generatedAt: String
        var timezone: String
        var steps: Int?
        var distanceKm: Double?
        var activeEnergyKcal: Double?
        var exerciseMinutes: Int?
        var standHours: Int?
        var restingHeartRateBpm: Int?
        var hrvMs: Double?
        var vo2Max: Double?
        var weightKg: Double?
        var goals: Goals?
        var sleep: Sleep?

        enum CodingKeys: String, CodingKey {
            case schemaVersion = "schema_version"
            case date
            case generatedAt = "generated_at"
            case timezone
            case steps
            case distanceKm = "distance_km"
            case activeEnergyKcal = "active_energy_kcal"
            case exerciseMinutes = "exercise_minutes"
            case standHours = "stand_hours"
            case restingHeartRateBpm = "resting_heart_rate_bpm"
            case hrvMs = "hrv_ms"
            case vo2Max = "vo2_max"
            case weightKg = "weight_kg"
            case goals
            case sleep
        }
    }

    struct Goals: Encodable {
        var moveKcal: Double?
        var exerciseMinutes: Int?
        var standHours: Int?

        enum CodingKeys: String, CodingKey {
            case moveKcal = "move_kcal"
            case exerciseMinutes = "exercise_minutes"
            case standHours = "stand_hours"
        }
    }

    struct Sleep: Encodable {
        var start: String?
        var end: String?
        var totalMinutes: Int?
        var inBedMinutes: Int?
        var deepMinutes: Int?
        var remMinutes: Int?
        var coreMinutes: Int?
        var awakeMinutes: Int?

        enum CodingKeys: String, CodingKey {
            case start
            case end
            case totalMinutes = "total_minutes"
            case inBedMinutes = "in_bed_minutes"
            case deepMinutes = "deep_minutes"
            case remMinutes = "rem_minutes"
            case coreMinutes = "core_minutes"
            case awakeMinutes = "awake_minutes"
        }
    }
}
