import SwiftUI

struct TodayView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(AppModel.self) private var model
    @State private var showSettings = false

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    statusHeader

                    if !model.isHealthDataAvailable {
                        ContentUnavailableView(
                            "Health Data Unavailable",
                            systemImage: "heart.slash",
                            description: Text("This device does not provide Apple Health data.")
                        )
                    } else if let metrics = model.todayMetrics {
                        metricGrid(metrics)
                        if let sleep = metrics.sleep {
                            SleepCard(sleep: sleep)
                        }
                    } else {
                        ContentUnavailableView(
                            "No Health Data",
                            systemImage: "heart.text.square",
                            description: Text("Nothing to show yet. Move around, or check Health permissions in the Settings app.")
                        )
                    }

                    if model.settings.webhookURL == nil {
                        serverHint
                    }

                    syncButton
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("TRMNL Health")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Settings")
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .fullScreenCover(isPresented: showPrimer) {
                PrimerView()
            }
            .task {
                await model.refreshPreview()
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    Task { await model.refreshPreview() }
                }
            }
            .refreshable {
                await model.refreshPreview()
            }
        }
    }

    private var showPrimer: Binding<Bool> {
        Binding(
            get: { !model.settings.hasCompletedOnboarding },
            set: { _ in }
        )
    }

    // MARK: - Sections

    private var statusHeader: some View {
        HStack(spacing: 6) {
            switch model.syncStatus {
            case .idle:
                Image(systemName: "circle.dashed")
                    .foregroundStyle(.secondary)
                Text("Not synced yet")
            case .syncing:
                ProgressView()
                    .controlSize(.small)
                Text("Syncing…")
            case .success(let date):
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("Synced \(date, format: .relative(presentation: .named))")
            case .failure(let message):
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                Text(message)
                    .lineLimit(2)
            }
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func metricGrid(_ metrics: DailyMetrics) -> some View {
        LazyVGrid(columns: columns, spacing: 12) {
            MetricCard(
                systemImage: "figure.walk",
                tint: .green,
                caption: "Steps",
                value: metrics.steps.map { $0.formatted(.number) } ?? "–",
                unit: nil
            )
            MetricCard(
                systemImage: "point.topleft.down.to.point.bottomright.curvepath",
                tint: .blue,
                caption: "Distance",
                value: metrics.distanceKm.map { $0.formatted(.number.precision(.fractionLength(0...1))) } ?? "–",
                unit: "km"
            )
            MetricCard(
                systemImage: "flame.fill",
                tint: .orange,
                caption: "Active Energy",
                value: metrics.activeEnergyKcal.map { $0.formatted(.number.precision(.fractionLength(0))) } ?? "–",
                unit: "kcal"
            )
            MetricCard(
                systemImage: "stopwatch",
                tint: .teal,
                caption: "Exercise",
                value: metrics.exerciseMinutes.map { "\($0)" } ?? "–",
                unit: "min"
            )
            MetricCard(
                systemImage: "heart.fill",
                tint: .red,
                caption: "Resting HR",
                value: metrics.restingHeartRateBpm.map { "\($0)" } ?? "–",
                unit: "bpm"
            )
            MetricCard(
                systemImage: "scalemass",
                tint: .purple,
                caption: "Weight",
                value: metrics.weightKg.map { $0.formatted(.number.precision(.fractionLength(0...1))) } ?? "–",
                unit: "kg"
            )
        }
    }

    private var serverHint: some View {
        HStack(spacing: 8) {
            Image(systemName: "server.rack")
                .foregroundStyle(.secondary)
            Text("Set your server's webhook URL in Settings to start syncing.")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Spacer()
            Button("Set Up") {
                showSettings = true
            }
            .font(.footnote.bold())
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var syncButton: some View {
        Button {
            Task { await model.syncNow() }
        } label: {
            Text("Sync Now")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(model.syncStatus.isSyncing || model.settings.webhookURL == nil)
    }
}

/// Full-width sleep card: total on the left, stage breakdown on the right.
struct SleepCard: View {
    let sleep: SleepSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "bed.double.fill")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.indigo)
                Text("Sleep")
                    .foregroundStyle(.secondary)
                Spacer()
                if let start = sleep.start, let end = sleep.end {
                    Text("\(start, format: .dateTime.hour().minute()) – \(end, format: .dateTime.hour().minute())")
                        .foregroundStyle(.secondary)
                }
            }
            .font(.subheadline)

            HStack(alignment: .firstTextBaseline) {
                Text(Self.hoursMinutes(sleep.totalMinutes))
                    .font(.title.bold())
                    .fontDesign(.rounded)
                    .monospacedDigit()
                Spacer()
                stageLabel("Deep", sleep.deepMinutes)
                stageLabel("REM", sleep.remMinutes)
                stageLabel("Core", sleep.coreMinutes)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func stageLabel(_ name: String, _ minutes: Int?) -> some View {
        VStack(spacing: 2) {
            Text(Self.hoursMinutes(minutes))
                .font(.subheadline.bold())
                .monospacedDigit()
            Text(name)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    static func hoursMinutes(_ minutes: Int?) -> String {
        guard let minutes else { return "–" }
        return "\(minutes / 60)h \(minutes % 60)m"
    }
}

#Preview {
    TodayView()
        .environment(AppModel.preview)
}
