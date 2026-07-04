import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var settings = model.settings

        NavigationStack {
            Form {
                Section {
                    TextField("http://your-server:4567/api/custom_plugins/…", text: $settings.webhookURLString)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } header: {
                    Text("Server")
                } footer: {
                    if settings.webhookURLString.isEmpty {
                        Text("The webhook URL of your plugin on your LaraPaper or TRMNL server.")
                    } else if settings.webhookURL == nil {
                        Text("This does not look like a valid http(s) URL yet.")
                            .foregroundStyle(.red)
                    }
                }

                Section {
                    LabeledContent("Version", value: Self.appVersion)
                    Link(destination: URL(string: "https://github.com/jooooosef/trmnl-apple-health")!) {
                        Label("Source Code", systemImage: "chevron.left.forwardslash.chevron.right")
                    }
                } header: {
                    Text("About")
                } footer: {
                    Text("Health for TRMNL is an independent open source project and is not affiliated with or endorsed by TRMNL.")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private static var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "dev"
    }
}

#Preview {
    SettingsView()
        .environment(AppModel.preview)
}
