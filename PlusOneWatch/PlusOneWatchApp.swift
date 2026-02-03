import SwiftUI

@main
struct PlusOneWatchApp: App {
    @StateObject private var sessionManager = WatchSessionManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(sessionManager)
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var sessionManager: WatchSessionManager

    var body: some View {
        Group {
            switch sessionManager.workoutState {
            case .noWorkout:
                NoWorkoutView()

            case .active:
                if sessionManager.timerState.isRunning {
                    WatchTimerView(
                        timerState: sessionManager.timerState,
                        nextSet: sessionManager.nextSet
                    )
                } else if let currentSet = sessionManager.currentSet,
                          let workoutInfo = sessionManager.workoutInfo {
                    ActiveSetView(
                        workoutInfo: workoutInfo,
                        currentSet: currentSet,
                        completedSetsCount: sessionManager.completedSetsCount,
                        totalSetsCount: sessionManager.totalSetsCount
                    )
                } else {
                    NoWorkoutView()
                }

            case .allSetsDone:
                if let workoutInfo = sessionManager.workoutInfo {
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 40))
                            .foregroundStyle(.green)

                        Text("All Sets Done!")
                            .font(.headline)

                        Text("Complete workout on iPhone")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)

                        Text(workoutInfo.liftType)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                } else {
                    NoWorkoutView()
                }

            case .completed:
                if let workoutInfo = sessionManager.workoutInfo {
                    WorkoutCompleteView(
                        workoutInfo: workoutInfo,
                        totalSetsCount: sessionManager.totalSetsCount
                    )
                } else {
                    NoWorkoutView()
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(WatchSessionManager.shared)
}
