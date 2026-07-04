import SwiftUI

/// One-screen HealthKit permission primer, shown once on first launch.
/// Tapping Continue triggers the system authorization sheet.
struct PrimerView: View {
    @Environment(AppModel.self) private var model
    @State private var isRequesting = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Image(systemName: "waveform.path.ecg.rectangle")
                .font(.system(size: 56))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.tint)
                .padding(.bottom, 16)

            Text("Your health, on paper.")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
                .padding(.bottom, 32)

            VStack(alignment: .leading, spacing: 20) {
                benefitRow(
                    systemImage: "heart.text.square",
                    title: "Reads your Health data",
                    detail: "Steps, sleep, heart rate and more — summarized once a day."
                )
                benefitRow(
                    systemImage: "server.rack",
                    title: "Sends it only to your server",
                    detail: "A small summary goes to the TRMNL server you host yourself."
                )
                benefitRow(
                    systemImage: "rectangle.portrait.on.rectangle.portrait",
                    title: "Shows it on your TRMNL",
                    detail: "Your day at a glance, on e-ink."
                )
            }
            .padding(.horizontal, 8)

            Spacer()

            Text("Your data never touches a third party.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.bottom, 12)

            Button {
                isRequesting = true
                Task {
                    await model.completeOnboarding()
                }
            } label: {
                Text("Continue")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(isRequesting)
        }
        .padding(24)
        .interactiveDismissDisabled()
    }

    private func benefitRow(systemImage: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: systemImage)
                .font(.title2)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.tint)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    PrimerView()
        .environment(AppModel.preview)
}
