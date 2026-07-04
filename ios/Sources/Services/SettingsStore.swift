import Foundation
import Observation

@Observable
final class SettingsStore {
    private static let webhookURLKey = "webhookURLString"
    private static let onboardingKey = "hasCompletedOnboarding"

    private let defaults: UserDefaults

    var webhookURLString: String {
        didSet { defaults.set(webhookURLString, forKey: Self.webhookURLKey) }
    }

    var hasCompletedOnboarding: Bool {
        didSet { defaults.set(hasCompletedOnboarding, forKey: Self.onboardingKey) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.webhookURLString = defaults.string(forKey: Self.webhookURLKey) ?? ""
        self.hasCompletedOnboarding = defaults.bool(forKey: Self.onboardingKey)
    }

    /// The validated webhook URL, or nil when unset/invalid.
    var webhookURL: URL? {
        let trimmed = webhookURLString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed),
              let scheme = url.scheme?.lowercased(),
              ["http", "https"].contains(scheme),
              url.host() != nil
        else { return nil }
        return url
    }
}
