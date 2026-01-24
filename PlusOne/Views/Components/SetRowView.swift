import SwiftUI

struct SetRowView: View {
    let set: WorkoutSet
    let plates: [Double]
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 12) {
                        // Set type indicator
                        Text(setTypeLabel)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(setTypeColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(setTypeColor.opacity(0.15))
                            .clipShape(Capsule())

                        // Weight
                        Text("\(PlateCalculator.formatWeight(set.targetWeight)) lbs")
                            .font(.title2)
                            .fontWeight(.semibold)

                        // Reps
                        Text("× \(set.repDisplay)")
                            .font(.title3)
                            .foregroundStyle(set.isAMRAP ? .orange : .primary)
                            .fontWeight(set.isAMRAP ? .bold : .regular)
                    }

                    PlateLoadingView(plates: plates)
                }

                Spacer()

                // Completion status
                if set.isComplete {
                    VStack(alignment: .trailing) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.green)

                        if let actualReps = set.actualReps {
                            Text("\(actualReps) reps")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    Image(systemName: "circle")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private var setTypeLabel: String {
        if set.isWarmup {
            return "Warmup"
        } else if set.isBBB {
            return "BBB"
        } else if set.isAMRAP {
            return "AMRAP"
        } else {
            return "Work"
        }
    }

    private var setTypeColor: Color {
        if set.isWarmup {
            return .yellow
        } else if set.isAMRAP {
            return .orange
        } else if set.isBBB {
            return .blue
        } else {
            return .primary
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        SetRowView(
            set: {
                let s = WorkoutSet(setNumber: 0, targetWeight: 185, targetReps: 5)
                return s
            }(),
            plates: [45, 25],
            onTap: {}
        )

        SetRowView(
            set: {
                let s = WorkoutSet(setNumber: 2, targetWeight: 225, targetReps: 5, isAMRAP: true)
                return s
            }(),
            plates: [45, 45],
            onTap: {}
        )

        SetRowView(
            set: {
                let s = WorkoutSet(setNumber: 3, targetWeight: 135, targetReps: 10, isBBB: true)
                s.complete(reps: 10)
                return s
            }(),
            plates: [45],
            onTap: {}
        )
    }
    .padding()
}
