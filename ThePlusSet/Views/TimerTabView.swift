import SwiftUI
import SwiftData
import AudioToolbox

struct TimerTabView: View {
    @EnvironmentObject var timerVM: TimerViewModel
    @Query private var settingsArray: [AppSettings]

    private var settings: AppSettings {
        settingsArray.first ?? AppSettings()
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                if timerVM.isRunning || timerVM.remainingSeconds > 0 {
                    // Timer is active
                    activeTimerView
                } else {
                    // No timer running
                    noTimerView
                }
            }
            .padding()
            .navigationTitle("Rest Timer")
        }
    }

    private var activeTimerView: some View {
        VStack(spacing: 24) {
            Spacer()

            // Progress circle with time
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 12)

                Circle()
                    .trim(from: 0, to: timerVM.progress)
                    .stroke(
                        timerVM.remainingSeconds <= 10 ? Color.red : Color.blue,
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: timerVM.progress)

                VStack(spacing: 8) {
                    Text(timerVM.timeString)
                        .font(.system(size: 64, weight: .bold, design: .monospaced))
                        .foregroundStyle(timerVM.remainingSeconds <= 10 ? .red : .primary)

                    Text("Rest")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 260, height: 260)

            // Time adjustment controls
            HStack(spacing: 16) {
                Button {
                    timerVM.addTime(seconds: -15)
                } label: {
                    Text("-15s")
                        .font(.headline)
                        .frame(width: 70, height: 44)
                }
                .buttonStyle(.bordered)
                .disabled(timerVM.remainingSeconds <= 15)

                Button {
                    timerVM.addTime(seconds: 15)
                } label: {
                    Text("+15s")
                        .font(.headline)
                        .frame(width: 70, height: 44)
                }
                .buttonStyle(.bordered)

                Button {
                    timerVM.addTime(seconds: 60)
                } label: {
                    Text("+1m")
                        .font(.headline)
                        .frame(width: 70, height: 44)
                }
                .buttonStyle(.bordered)
            }

            // Stop button
            Button {
                timerVM.stop()
            } label: {
                Label("Stop Timer", systemImage: "stop.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)

            Spacer()
        }
    }

    private var noTimerView: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "timer")
                .font(.system(size: 80))
                .foregroundStyle(.secondary)

            Text("No Timer Running")
                .font(.title2)
                .foregroundStyle(.secondary)

            VStack(spacing: 12) {
                Text("Quick Start")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    quickStartButton(label: "Warmup", seconds: settings.warmupRestSeconds)
                    quickStartButton(label: "Working Sets", seconds: settings.mainSetRestSeconds)
                    quickStartButton(label: "BBB Sets", seconds: settings.bbbSetRestSeconds)
                    quickStartButton(label: "Custom", seconds: 120)
                }
            }
            .padding(.horizontal)

            Spacer()

            Text("Timer will start automatically after logging a set")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private func quickStartButton(label: String, seconds: Int) -> some View {
        Button {
            NotificationManager.shared.chimeSoundID = SystemSoundID(settings.timerChimeSoundID)
            timerVM.start(seconds: seconds)
        } label: {
            VStack(spacing: 4) {
                Text(label)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(formatTime(seconds))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
        }
        .buttonStyle(.bordered)
    }

    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        if secs == 0 {
            return "\(mins) min"
        } else {
            return "\(mins):\(String(format: "%02d", secs))"
        }
    }
}

#Preview {
    TimerTabView()
        .environmentObject(TimerViewModel())
        .modelContainer(for: [AppSettings.self])
}
