import Foundation
import WatchConnectivity
import WatchKit

/// Manages WatchConnectivity session on the watchOS side, receiving workout updates from phone
@MainActor
class WatchSessionManager: NSObject, ObservableObject {
    static let shared = WatchSessionManager()

    private var session: WCSession?

    // MARK: - Published State

    @Published var workoutState: WorkoutState = .noWorkout
    @Published var timerState: TimerState = TimerState()
    @Published var workoutInfo: WatchWorkoutInfo?
    @Published var currentSet: WatchSetInfo?
    @Published var nextSet: WatchSetInfo?
    @Published var completedSetsCount: Int = 0
    @Published var totalSetsCount: Int = 0

    // Timer tick tracking for throttled updates
    private var lastTickUpdate: Date = .distantPast

    // Local timer for independent countdown
    private var localTimer: Timer?

    override init() {
        super.init()
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }

    // MARK: - Haptic Feedback

    private func playHaptic(_ type: WKHapticType) {
        WKInterfaceDevice.current().play(type)
    }

    func playTimerWarningHaptic() {
        playHaptic(.notification)
    }

    func playTimerCompleteHaptic() {
        // Play success haptic twice for stronger notification
        playHaptic(.success)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            WKInterfaceDevice.current().play(.success)
        }
    }

    // MARK: - Local Timer (for independent countdown when phone sleeps)

    private func startLocalTimer() {
        stopLocalTimer()
        localTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateTimerFromEndDate()
            }
        }
    }

    private func stopLocalTimer() {
        localTimer?.invalidate()
        localTimer = nil
    }

    private func updateTimerFromEndDate() {
        guard timerState.isRunning, let endDate = timerState.endDate else { return }

        let previousRemaining = timerState.remainingSeconds
        let remaining = max(0, Int(ceil(endDate.timeIntervalSinceNow)))

        timerState.remainingSeconds = remaining

        // Haptic at 30 seconds
        if previousRemaining > 30 && remaining <= 30 && remaining > 0 {
            playTimerWarningHaptic()
        }

        // Timer completed
        if remaining == 0 && previousRemaining > 0 {
            timerState.isRunning = false
            stopLocalTimer()
            playTimerCompleteHaptic()
        }
    }
}

// MARK: - WCSessionDelegate

extension WatchSessionManager: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("WCSession activation failed: \(error.localizedDescription)")
        } else {
            print("WCSession activated with state: \(activationState.rawValue)")

            // Check for application context on activation
            Task { @MainActor in
                self.processApplicationContext(session.receivedApplicationContext)
            }
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        Task { @MainActor in
            self.processMessage(message)
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        Task { @MainActor in
            self.processApplicationContext(applicationContext)
        }
    }
}

// MARK: - Message Processing

extension WatchSessionManager {
    private func processMessage(_ message: [String: Any]) {
        guard let type = message["type"] as? String else { return }

        switch type {
        case "workoutStarted":
            processWorkoutStarted(message)
        case "setUpdated":
            processSetUpdated(message)
        case "timerUpdated":
            processTimerUpdated(message)
        case "workoutCompleted":
            processWorkoutCompleted(message)
        case "workoutCleared":
            processWorkoutCleared()
        default:
            break
        }
    }

    private func processApplicationContext(_ context: [String: Any]) {
        guard !context.isEmpty else {
            workoutState = .noWorkout
            return
        }

        // Application context uses the same format as messages
        processMessage(context)
    }

    private func processWorkoutStarted(_ message: [String: Any]) {
        updateWorkoutInfo(from: message)
        updateCurrentSet(from: message)
        updateNextSet(from: message)
        updateProgress(from: message)

        workoutState = .active
        playHaptic(.start)
    }

    private func processSetUpdated(_ message: [String: Any]) {
        updateWorkoutInfo(from: message)
        updateCurrentSet(from: message)
        updateNextSet(from: message)
        updateProgress(from: message)

        // If no current set, all sets are done
        if currentSet == nil && completedSetsCount == totalSetsCount && totalSetsCount > 0 {
            workoutState = .allSetsDone
        } else {
            workoutState = .active
        }
    }

    private func processTimerUpdated(_ message: [String: Any]) {
        let remainingSeconds = message["remainingSeconds"] as? Int ?? 0
        let totalSeconds = message["totalSeconds"] as? Int ?? 0
        let isRunning = message["isRunning"] as? Bool ?? false

        // Extract end date for independent time calculation
        var endDate: Date? = nil
        if let timestamp = message["timerEndTimestamp"] as? TimeInterval {
            endDate = Date(timeIntervalSince1970: timestamp)
        }

        let previousRemaining = timerState.remainingSeconds
        let wasRunning = timerState.isRunning

        timerState = TimerState(
            remainingSeconds: remainingSeconds,
            totalSeconds: totalSeconds,
            isRunning: isRunning,
            endDate: endDate
        )

        updateNextSet(from: message)

        // Start or stop local timer based on running state
        if isRunning && !wasRunning {
            startLocalTimer()
        } else if !isRunning && wasRunning {
            stopLocalTimer()
        }

        // Ensure workout state is active when timer is running
        if isRunning && workoutState != .active {
            workoutState = .active
        }

        // Haptic feedback at 30 seconds
        if wasRunning && isRunning && previousRemaining > 30 && remainingSeconds <= 30 && remainingSeconds > 0 {
            playTimerWarningHaptic()
        }

        // Haptic feedback when timer completes
        if wasRunning && !isRunning && remainingSeconds == 0 {
            playTimerCompleteHaptic()
        }
    }

    private func processWorkoutCompleted(_ message: [String: Any]) {
        updateWorkoutInfo(from: message)
        updateProgress(from: message)

        workoutState = .completed
        currentSet = nil
        nextSet = nil
        timerState = TimerState()

        playHaptic(.success)
    }

    private func processWorkoutCleared() {
        workoutState = .noWorkout
        workoutInfo = nil
        currentSet = nil
        nextSet = nil
        completedSetsCount = 0
        totalSetsCount = 0
        timerState = TimerState()
    }

    // MARK: - Helper Methods

    private func updateWorkoutInfo(from message: [String: Any]) {
        guard let workoutDict = message["workout"] as? [String: Any] else { return }

        workoutInfo = WatchWorkoutInfo(
            liftType: workoutDict["liftType"] as? String ?? "",
            weekNumber: workoutDict["weekNumber"] as? Int ?? 1,
            cycleNumber: workoutDict["cycleNumber"] as? Int ?? 1
        )
    }

    private func updateCurrentSet(from message: [String: Any]) {
        guard let setDict = message["currentSet"] as? [String: Any] else {
            currentSet = nil
            return
        }

        currentSet = WatchSetInfo(from: setDict)
    }

    private func updateNextSet(from message: [String: Any]) {
        guard let setDict = message["nextSet"] as? [String: Any] else {
            nextSet = nil
            return
        }

        nextSet = WatchSetInfo(from: setDict)
    }

    private func updateProgress(from message: [String: Any]) {
        completedSetsCount = message["completedSetsCount"] as? Int ?? 0
        totalSetsCount = message["totalSetsCount"] as? Int ?? 0
    }
}

// MARK: - State Models

enum WorkoutState {
    case noWorkout
    case active
    case allSetsDone
    case completed
}

struct TimerState {
    var remainingSeconds: Int = 0
    var totalSeconds: Int = 0
    var isRunning: Bool = false
    var endDate: Date? = nil  // Used for independent time calculation

    var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return Double(totalSeconds - remainingSeconds) / Double(totalSeconds)
    }

    var timeString: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    /// Calculate current remaining seconds based on end date
    func calculatedRemainingSeconds() -> Int {
        guard let endDate = endDate, isRunning else { return remainingSeconds }
        let remaining = endDate.timeIntervalSinceNow
        return max(0, Int(ceil(remaining)))
    }
}

struct WatchWorkoutInfo {
    let liftType: String
    let weekNumber: Int
    let cycleNumber: Int

    var weekDescription: String {
        switch weekNumber {
        case 1: return "5/5/5+"
        case 2: return "3/3/3+"
        case 3: return "5/3/1+"
        case 4: return "Deload"
        default: return "Week \(weekNumber)"
        }
    }
}

struct WatchSetInfo {
    let setNumber: Int
    let targetWeight: Double
    let targetReps: Int
    let isAMRAP: Bool
    let setType: String
    let plates: [Double]

    init(from dict: [String: Any]) {
        self.setNumber = dict["setNumber"] as? Int ?? 0
        self.targetWeight = dict["targetWeight"] as? Double ?? 0
        self.targetReps = dict["targetReps"] as? Int ?? 0
        self.isAMRAP = dict["isAMRAP"] as? Bool ?? false
        self.setType = dict["setType"] as? String ?? ""
        self.plates = dict["plates"] as? [Double] ?? []
    }

    var repDisplay: String {
        isAMRAP ? "\(targetReps)+" : "\(targetReps)"
    }

    var weightDisplay: String {
        if targetWeight.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", targetWeight)
        } else {
            return String(format: "%.1f", targetWeight)
        }
    }

    var platesDisplay: String {
        if plates.isEmpty { return "Empty bar" }

        var formatted: [String] = []
        var currentPlate: Double? = nil
        var count = 0

        for plate in plates {
            if plate == currentPlate {
                count += 1
            } else {
                if let current = currentPlate {
                    let plateStr = current.truncatingRemainder(dividingBy: 1) == 0
                        ? String(format: "%.0f", current)
                        : String(format: "%.1f", current)
                    formatted.append(count > 1 ? "\(plateStr)x\(count)" : plateStr)
                }
                currentPlate = plate
                count = 1
            }
        }

        if let current = currentPlate {
            let plateStr = current.truncatingRemainder(dividingBy: 1) == 0
                ? String(format: "%.0f", current)
                : String(format: "%.1f", current)
            formatted.append(count > 1 ? "\(plateStr)x\(count)" : plateStr)
        }

        return formatted.joined(separator: " + ")
    }

    var setTypeColor: String {
        switch setType {
        case "Warmup": return "yellow"
        case "AMRAP": return "orange"
        case "BBB": return "blue"
        default: return "primary"
        }
    }
}
