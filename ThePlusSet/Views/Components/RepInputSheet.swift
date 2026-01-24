import SwiftUI

struct RepInputSheet: View {
    let set: WorkoutSet
    let onComplete: (Int) -> Void
    let onCancel: () -> Void

    @State private var reps: Int
    @FocusState private var isFocused: Bool

    init(set: WorkoutSet, onComplete: @escaping (Int) -> Void, onCancel: @escaping () -> Void) {
        self.set = set
        self.onComplete = onComplete
        self.onCancel = onCancel
        self._reps = State(initialValue: set.targetReps)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Set info
                    VStack(spacing: 8) {
                        Text("\(PlateCalculator.formatWeight(set.targetWeight)) lbs")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        if set.isAMRAP {
                            Text("AMRAP Set - How many did you get?")
                                .font(.headline)
                                .foregroundStyle(.orange)
                        } else {
                            Text("Target: \(set.targetReps) reps")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                        }
                    }

                    // Rep input
                    VStack(spacing: 16) {
                        HStack(spacing: 20) {
                            Button {
                                if reps > 1 { reps -= 1 }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.system(size: 44))
                                    .foregroundStyle(.blue)
                            }

                            Text("\(reps)")
                                .font(.system(size: 72, weight: .bold, design: .rounded))
                                .frame(minWidth: 100)

                            Button {
                                reps += 1
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 44))
                                    .foregroundStyle(.blue)
                            }
                        }

                        Text("reps")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }

                    // Quick select buttons for AMRAP
                    if set.isAMRAP {
                        VStack(spacing: 8) {
                            Text("Quick Select")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 8) {
                                ForEach(quickSelectRange, id: \.self) { num in
                                    Button {
                                        reps = num
                                    } label: {
                                        Text("\(num)")
                                            .font(.headline)
                                            .frame(width: 50, height: 44)
                                            .background(reps == num ? Color.blue : Color(.secondarySystemBackground))
                                            .foregroundStyle(reps == num ? .white : .primary)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                }
                            }
                        }
                    }

                    // Complete button
                    Button {
                        onComplete(reps)
                    } label: {
                        Text("Complete Set")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.top, 20)
                }
                .padding()
            }
            .navigationTitle("Log Reps")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
            }
        }
    }

    private var quickSelectRange: [Int] {
        let base = set.targetReps
        let start = max(1, base - 2)
        let end = base + 7
        return Array(start...end)
    }
}

#Preview {
    RepInputSheet(
        set: WorkoutSet(setNumber: 2, targetWeight: 225, targetReps: 5, isAMRAP: true),
        onComplete: { _ in },
        onCancel: {}
    )
}
