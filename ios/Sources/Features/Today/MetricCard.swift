import SwiftUI

/// Big-numeral metric card: small icon + caption on top, hero number below.
struct MetricCard: View {
    let systemImage: String
    let tint: Color
    let caption: String
    let value: String
    let unit: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(tint)
                Text(caption)
                    .foregroundStyle(.secondary)
            }
            .font(.subheadline)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.title.bold())
                    .fontDesign(.rounded)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                if let unit {
                    Text(unit)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

#Preview {
    MetricCard(systemImage: "figure.walk", tint: .green, caption: "Steps", value: "8,342", unit: nil)
        .padding()
        .background(Color(.systemGroupedBackground))
}
