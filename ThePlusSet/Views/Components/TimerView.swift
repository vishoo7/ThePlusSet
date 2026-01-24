import SwiftUI

struct TimerView: View {
    @ObservedObject var timerVM: TimerViewModel
    let onAddTime: (Int) -> Void
    let onStop: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            // Progress circle with time
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 8)

                Circle()
                    .trim(from: 0, to: timerVM.progress)
                    .stroke(
                        timerVM.remainingSeconds <= 10 ? Color.red : Color.blue,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: timerVM.progress)

                VStack(spacing: 4) {
                    Text(timerVM.timeString)
                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                        .foregroundStyle(timerVM.remainingSeconds <= 10 ? .red : .primary)

                    Text("Rest")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 180, height: 180)

            // Time adjustment controls
            HStack(spacing: 12) {
                Button {
                    onAddTime(-30)
                } label: {
                    Text("-30s")
                        .font(.subheadline)
                        .frame(width: 50)
                }
                .buttonStyle(.bordered)
                .disabled(timerVM.remainingSeconds <= 30)

                Button {
                    onAddTime(30)
                } label: {
                    Text("+30s")
                        .font(.subheadline)
                        .frame(width: 50)
                }
                .buttonStyle(.bordered)

                Button {
                    onAddTime(60)
                } label: {
                    Text("+1m")
                        .font(.subheadline)
                        .frame(width: 50)
                }
                .buttonStyle(.bordered)
            }

            // Skip button
            Button {
                onStop()
            } label: {
                Label("Skip Rest", systemImage: "forward.fill")
                    .font(.subheadline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.orange)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(radius: 10)
    }
}

#Preview {
    TimerView(
        timerVM: {
            let vm = TimerViewModel()
            Task { @MainActor in
                vm.start(seconds: 180)
            }
            return vm
        }(),
        onAddTime: { _ in },
        onStop: {}
    )
    .padding()
    .background(Color.gray.opacity(0.3))
}
