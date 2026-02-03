import SwiftUI

struct ActiveSetView: View {
    let workoutInfo: WatchWorkoutInfo
    let currentSet: WatchSetInfo
    let completedSetsCount: Int
    let totalSetsCount: Int

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                // Header with lift type and week
                HStack {
                    Text(workoutInfo.liftType)
                        .font(.caption)
                        .fontWeight(.medium)

                    Spacer()

                    Text(workoutInfo.weekDescription)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                // Progress bar
                ProgressView(value: Double(completedSetsCount), total: Double(totalSetsCount))
                    .tint(.blue)

                Text("\(completedSetsCount)/\(totalSetsCount) sets")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Divider()
                    .padding(.vertical, 4)

                // Set type badge
                Text(currentSet.setType)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(setTypeBackgroundColor)
                    .foregroundStyle(setTypeForegroundColor)
                    .clipShape(Capsule())

                // Main weight display
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(currentSet.weightDisplay)
                        .font(.system(size: 44, weight: .bold, design: .rounded))

                    Text("lbs")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // Reps display
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(currentSet.repDisplay)
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .foregroundStyle(currentSet.isAMRAP ? .orange : .primary)

                    Text("reps")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // AMRAP indicator
                if currentSet.isAMRAP {
                    Text("AMRAP")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.orange)
                }

                // Plate loading
                if !currentSet.plates.isEmpty {
                    Divider()
                        .padding(.vertical, 4)

                    Text("Per side")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Text(currentSet.platesDisplay)
                        .font(.caption)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal)
        }
    }

    private var setTypeBackgroundColor: Color {
        switch currentSet.setType {
        case "Warmup": return .yellow.opacity(0.3)
        case "AMRAP": return .orange.opacity(0.3)
        case "BBB": return .blue.opacity(0.3)
        default: return .gray.opacity(0.3)
        }
    }

    private var setTypeForegroundColor: Color {
        switch currentSet.setType {
        case "Warmup": return .yellow
        case "AMRAP": return .orange
        case "BBB": return .blue
        default: return .primary
        }
    }
}

#Preview {
    ActiveSetView(
        workoutInfo: WatchWorkoutInfo(liftType: "Squat", weekNumber: 3, cycleNumber: 1),
        currentSet: WatchSetInfo(from: [
            "setNumber": 6,
            "targetWeight": 225.0,
            "targetReps": 1,
            "isAMRAP": true,
            "setType": "AMRAP",
            "plates": [45.0, 45.0, 25.0, 5.0, 2.5]
        ]),
        completedSetsCount: 5,
        totalSetsCount: 11
    )
}
