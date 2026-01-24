import Foundation
import Combine

@MainActor
class TimerViewModel: ObservableObject {
    @Published var remainingSeconds: Int = 0
    @Published var isRunning: Bool = false
    @Published var totalSeconds: Int = 0

    // Next set info for display during rest
    @Published var nextSetWeight: Double?
    @Published var nextSetReps: Int?
    @Published var nextSetPlates: [Double] = []
    @Published var nextSetIsAMRAP: Bool = false

    private var timer: Timer?
    private let notificationManager = NotificationManager.shared

    var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return Double(totalSeconds - remainingSeconds) / Double(totalSeconds)
    }

    var timeString: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    func start(seconds: Int) {
        start(seconds: seconds, nextSetWeight: nil, nextSetReps: nil, nextSetPlates: [], nextSetIsAMRAP: false)
    }

    func start(seconds: Int, nextSetWeight: Double?, nextSetReps: Int?, nextSetPlates: [Double], nextSetIsAMRAP: Bool) {
        stop()
        totalSeconds = seconds
        remainingSeconds = seconds
        isRunning = true

        // Store next set info
        self.nextSetWeight = nextSetWeight
        self.nextSetReps = nextSetReps
        self.nextSetPlates = nextSetPlates
        self.nextSetIsAMRAP = nextSetIsAMRAP

        notificationManager.scheduleRestTimerNotification(seconds: seconds)

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        remainingSeconds = 0
        totalSeconds = 0
        nextSetWeight = nil
        nextSetReps = nil
        nextSetPlates = []
        nextSetIsAMRAP = false
        notificationManager.cancelRestTimerNotification()
    }

    func addTime(seconds: Int) {
        let newRemaining = max(1, remainingSeconds + seconds)
        let newTotal = max(1, totalSeconds + seconds)
        remainingSeconds = newRemaining
        totalSeconds = newTotal
        // Reschedule notification
        notificationManager.cancelRestTimerNotification()
        if remainingSeconds > 0 {
            notificationManager.scheduleRestTimerNotification(seconds: remainingSeconds)
        }
    }

    private func tick() {
        if remainingSeconds > 0 {
            remainingSeconds -= 1
        }

        if remainingSeconds == 0 {
            complete()
        }
    }

    private func complete() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        notificationManager.triggerTimerCompletion()
    }
}
