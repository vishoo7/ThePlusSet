import SwiftUI

struct WatchTimerView: View {
    @EnvironmentObject var sessionManager: WatchSessionManager
    let nextSet: WatchSetInfo?

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1.0)) { context in
            let remaining = computeRemaining()
            let total = sessionManager.timerState.totalSeconds

            VStack(spacing: 8) {
                // Timer ring
                ZStack {
                    // Background ring
                    Circle()
                        .stroke(lineWidth: 8)
                        .foregroundStyle(.gray.opacity(0.3))

                    // Progress ring
                    Circle()
                        .trim(from: 0, to: progress(remaining: remaining, total: total))
                        .stroke(style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .foregroundStyle(timerColor(remaining: remaining))
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.5), value: progress(remaining: remaining, total: total))

                    // Time display
                    VStack(spacing: 2) {
                        Text(timeString(remaining: remaining))
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(timerColor(remaining: remaining))

                        Text("REST")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 120, height: 120)

                // Next set preview
                if let next = nextSet {
                    Divider()
                        .padding(.vertical, 4)

                    VStack(spacing: 4) {
                        Text("Next Up")
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 4) {
                            Text(next.weightDisplay)
                                .font(.headline)
                                .fontWeight(.bold)

                            Text("x")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text(next.repDisplay)
                                .font(.headline)
                                .foregroundStyle(next.isAMRAP ? .orange : .primary)
                        }

                        Text(next.setType)
                            .font(.caption2)
                            .foregroundStyle(nextSetTypeColor(next.setType))

                        // Plates per side
                        Text(next.platesDisplay)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            .padding()
            .onChange(of: remaining) { oldValue, newValue in
                sessionManager.handleTimerTick(previousRemaining: oldValue, currentRemaining: newValue)
            }
        }
    }

    private func computeRemaining() -> Int {
        guard let endDate = sessionManager.timerState.endDate,
              sessionManager.timerState.isRunning else {
            return sessionManager.timerState.remainingSeconds
        }
        return max(0, Int(ceil(endDate.timeIntervalSinceNow)))
    }

    private func progress(remaining: Int, total: Int) -> Double {
        guard total > 0 else { return 0 }
        return Double(total - remaining) / Double(total)
    }

    private func timeString(remaining: Int) -> String {
        let minutes = remaining / 60
        let seconds = remaining % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private func timerColor(remaining: Int) -> Color {
        if remaining <= 10 {
            return .red
        } else if remaining <= 30 {
            return .orange
        } else {
            return .blue
        }
    }

    private func nextSetTypeColor(_ type: String) -> Color {
        switch type {
        case "Warmup": return .yellow
        case "AMRAP": return .orange
        case "BBB": return .blue
        default: return .secondary
        }
    }
}

#Preview {
    WatchTimerView(
        nextSet: WatchSetInfo(from: [
            "setNumber": 7,
            "targetWeight": 185.0,
            "targetReps": 10,
            "isAMRAP": false,
            "setType": "BBB",
            "plates": [45.0, 25.0]
        ])
    )
    .environmentObject(WatchSessionManager.shared)
}
