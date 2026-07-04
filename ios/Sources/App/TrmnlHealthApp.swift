import SwiftUI

@main
struct TrmnlHealthApp: App {
    @State private var model: AppModel

    init() {
        let settings = SettingsStore()
        let reader = HealthKitReader()
        let engine = SyncEngine(
            reader: reader,
            client: URLSessionWebhookClient(),
            settings: settings
        )
        _model = State(initialValue: AppModel(reader: reader, engine: engine, settings: settings))
    }

    var body: some Scene {
        WindowGroup {
            TodayView()
                .environment(model)
        }
    }
}
