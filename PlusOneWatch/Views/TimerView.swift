import SwiftUI

struct WatchTimerView: View {
    let timerState: TimerState
    let nextSet: WatchSetInfo?

    var body: some View {
        VStack(spacing: 8) {
            // Timer ring
            ZStack {
                // Background ring
                Circle()
                    .stroke(lineWidth: 8)
                    .foregroundStyle(.gray.opacity(0.3))

                // Progress ring
                Circle()
                    .trim(from: 0, to: timerState.progress)
                    .stroke(style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .foregroundStyle(timerColor)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.5), value: timerState.progress)

                // Time display
                VStack(spacing: 2) {
                    Text(timerState.timeString)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(timerColor)

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
                }
            }
        }
        .padding()
    }

    private var timerColor: Color {
        if timerState.remainingSeconds <= 10 {
            return .red
        } else if timerState.remainingSeconds <= 30 {
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
        timerState: TimerState(remainingSeconds: 45, totalSeconds: 180, isRunning: true),
        nextSet: WatchSetInfo(from: [
            "setNumber": 7,
            "targetWeight": 185.0,
            "targetReps": 10,
            "isAMRAP": false,
            "setType": "BBB",
            "plates": [45.0, 25.0]
        ])
    )
}
