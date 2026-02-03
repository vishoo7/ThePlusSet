import SwiftUI

struct NextSetPreview: View {
    let nextSet: WatchSetInfo

    var body: some View {
        VStack(spacing: 6) {
            Text("Next Set")
                .font(.caption2)
                .foregroundStyle(.secondary)

            // Set type badge
            Text(nextSet.setType)
                .font(.caption2)
                .fontWeight(.semibold)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(setTypeBackgroundColor)
                .foregroundStyle(setTypeForegroundColor)
                .clipShape(Capsule())

            // Weight and reps
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(nextSet.weightDisplay)
                    .font(.system(size: 20, weight: .bold, design: .rounded))

                Text("x")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(nextSet.repDisplay)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(nextSet.isAMRAP ? .orange : .primary)
            }

            // Plates
            Text(nextSet.platesDisplay)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.gray.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var setTypeBackgroundColor: Color {
        switch nextSet.setType {
        case "Warmup": return .yellow.opacity(0.3)
        case "AMRAP": return .orange.opacity(0.3)
        case "BBB": return .blue.opacity(0.3)
        default: return .gray.opacity(0.3)
        }
    }

    private var setTypeForegroundColor: Color {
        switch nextSet.setType {
        case "Warmup": return .yellow
        case "AMRAP": return .orange
        case "BBB": return .blue
        default: return .primary
        }
    }
}

#Preview {
    NextSetPreview(
        nextSet: WatchSetInfo(from: [
            "setNumber": 4,
            "targetWeight": 185.0,
            "targetReps": 5,
            "isAMRAP": true,
            "setType": "AMRAP",
            "plates": [45.0, 25.0]
        ])
    )
}
