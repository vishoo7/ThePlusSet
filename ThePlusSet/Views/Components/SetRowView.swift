import SwiftUI

struct SetRowView: View {
    let set: WorkoutSet
    let plates: [Double]
    let onTap: () -> Void
    var onQuickComplete: (() -> Void)? = nil
    var onUndo: (() -> Void)? = nil
    var canUndo: Bool = false

    var body: some View {
        HStack(spacing: 0) {
            // Main content area - tapping opens the rep input dialog
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
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Divider between content and quick complete
            if !set.isComplete {
                Rectangle()
                    .fill(Color(.separator))
                    .frame(width: 1)
                    .padding(.vertical, 8)
            }

            // Completion status / Quick complete button
            if set.isComplete {
                if canUndo {
                    Button {
                        onUndo?()
                    } label: {
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
                    }
                    .buttonStyle(.plain)
                    .padding(.leading, 12)
                } else {
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
                    .padding(.leading, 12)
                }
            } else {
                Button {
                    onQuickComplete?()
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.green)
                        Text("Done")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(width: 50)
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.leading)
        .padding(.vertical)
        .padding(.trailing, 8)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
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
