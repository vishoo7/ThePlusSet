import Foundation
import Combine
import UIKit

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
    @Published var nextSetType: String = ""  // "Warmup", "Working", "BBB"

    private var timer: Timer?
    private let notificationManager = NotificationManager.shared
    private let watchSession = PhoneSessionManager.shared
    private var lastWatchUpdate: Int = 0

    // Store end time to handle background suspension
    private var timerEndDate: Date?
    private var foregroundObserver: NSObjectProtocol?

    init() {
        // Listen for app returning to foreground to recalculate timer
        foregroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.recalculateTimeFromEndDate()
            }
        }
    }

    deinit {
        if let observer = foregroundObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

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
        start(seconds: seconds, nextSetWeight: nil, nextSetReps: nil, nextSetPlates: [], nextSetIsAMRAP: false, nextSetType: "")
    }

    func start(seconds: Int, nextSetWeight: Double?, nextSetReps: Int?, nextSetPlates: [Double], nextSetIsAMRAP: Bool, nextSetType: String = "") {
        stop()
        totalSeconds = seconds
        remainingSeconds = seconds
        isRunning = true
        lastWatchUpdate = seconds

        // Store end time for background handling
        timerEndDate = Date().addingTimeInterval(TimeInterval(seconds))

        // Store next set info
        self.nextSetWeight = nextSetWeight
        self.nextSetReps = nextSetReps
        self.nextSetPlates = nextSetPlates
        self.nextSetIsAMRAP = nextSetIsAMRAP
        self.nextSetType = nextSetType

        notificationManager.scheduleRestTimerNotification(seconds: seconds)

        // Send initial timer update to watch
        sendTimerUpdateToWatch()

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
        timerEndDate = nil
        nextSetWeight = nil
        nextSetReps = nil
        nextSetPlates = []
        nextSetIsAMRAP = false
        nextSetType = ""
        notificationManager.cancelRestTimerNotification()

        // Notify watch that timer stopped
        sendTimerUpdateToWatch()
    }

    /// Recalculate remaining time based on stored end date (called when app returns from background)
    private func recalculateTimeFromEndDate() {
        guard isRunning, let endDate = timerEndDate else { return }

        let now = Date()
        let remaining = endDate.timeIntervalSince(now)

        if remaining <= 0 {
            // Timer already expired while in background
            remainingSeconds = 0
            complete()
        } else {
            // Update remaining seconds based on actual time
            remainingSeconds = Int(ceil(remaining))
            sendTimerUpdateToWatch()
        }
    }

    func addTime(seconds: Int) {
        let newRemaining = max(1, remainingSeconds + seconds)
        let newTotal = max(1, totalSeconds + seconds)
        remainingSeconds = newRemaining
        totalSeconds = newTotal

        // Update end date
        timerEndDate = Date().addingTimeInterval(TimeInterval(newRemaining))

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

        // Send throttled timer updates to watch
        // Every 5 seconds normally, every 1 second when <= 10 seconds remaining
        let shouldUpdate = remainingSeconds <= 10 ||
                          (lastWatchUpdate - remainingSeconds >= 5)

        if shouldUpdate {
            sendTimerUpdateToWatch()
            lastWatchUpdate = remainingSeconds
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

        // Send final timer update to watch
        sendTimerUpdateToWatch()
    }

    private func sendTimerUpdateToWatch() {
        var nextSetInfo: SetInfo? = nil

        if let weight = nextSetWeight,
           let reps = nextSetReps {
            let setType: String
            if nextSetIsAMRAP {
                setType = "AMRAP"
            } else if nextSetType == "Warmup" {
                setType = "Warmup"
            } else if nextSetType == "BBB" {
                setType = "BBB"
            } else {
                setType = "Working"
            }

            nextSetInfo = SetInfo(
                setNumber: 0,
                targetWeight: weight,
                targetReps: reps,
                isAMRAP: nextSetIsAMRAP,
                setType: setType,
                plates: nextSetPlates
            )
        }

        watchSession.sendTimerUpdated(
            remainingSeconds: remainingSeconds,
            totalSeconds: totalSeconds,
            isRunning: isRunning,
            timerEndDate: timerEndDate,
            nextSet: nextSetInfo
        )
    }
}
