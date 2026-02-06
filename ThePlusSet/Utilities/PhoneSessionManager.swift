import Foundation
import WatchConnectivity

/// Manages WatchConnectivity session on the iOS side, sending workout updates to the watch
@MainActor
class PhoneSessionManager: NSObject, ObservableObject {
    static let shared = PhoneSessionManager()

    private var session: WCSession?

    // Current state for syncing
    private var lastWorkoutContext: [String: Any]?
    private var lastTimerContext: [String: Any]?

    override init() {
        super.init()
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }

    /// Send full current state to watch (called when watch becomes reachable or needs sync)
    func syncFullState() {
        // Send last workout context
        if let workoutContext = lastWorkoutContext {
            sendMessage(workoutContext)
        }
        // Send last timer context if timer is running
        if let timerContext = lastTimerContext,
           let isRunning = timerContext["isRunning"] as? Bool,
           isRunning {
            sendMessage(timerContext)
        }
    }

    // MARK: - Send Workout Started

    func sendWorkoutStarted(
        workout: WorkoutInfo,
        currentSet: SetInfo,
        nextSet: SetInfo?,
        completedSetsCount: Int,
        totalSetsCount: Int
    ) {
        var payload: [String: Any] = [
            "type": "workoutStarted",
            "workout": workout.toDictionary(),
            "currentSet": currentSet.toDictionary(),
            "completedSetsCount": completedSetsCount,
            "totalSetsCount": totalSetsCount
        ]

        if let next = nextSet {
            payload["nextSet"] = next.toDictionary()
        }

        sendMessage(payload)
        updateApplicationContext(payload)
    }

    // MARK: - Send Set Updated

    func sendSetUpdated(
        workout: WorkoutInfo,
        currentSet: SetInfo?,
        nextSet: SetInfo?,
        completedSetsCount: Int,
        totalSetsCount: Int
    ) {
        var payload: [String: Any] = [
            "type": "setUpdated",
            "workout": workout.toDictionary(),
            "completedSetsCount": completedSetsCount,
            "totalSetsCount": totalSetsCount
        ]

        if let current = currentSet {
            payload["currentSet"] = current.toDictionary()
        }

        if let next = nextSet {
            payload["nextSet"] = next.toDictionary()
        }

        sendMessage(payload)
        updateApplicationContext(payload)
    }

    // MARK: - Send Timer Updated

    func sendTimerUpdated(
        remainingSeconds: Int,
        totalSeconds: Int,
        isRunning: Bool,
        timerEndDate: Date?,
        nextSet: SetInfo?
    ) {
        var payload: [String: Any] = [
            "type": "timerUpdated",
            "remainingSeconds": remainingSeconds,
            "totalSeconds": totalSeconds,
            "isRunning": isRunning
        ]

        // Send end date so watch can calculate time independently
        if let endDate = timerEndDate {
            payload["timerEndTimestamp"] = endDate.timeIntervalSince1970
        }

        if let next = nextSet {
            payload["nextSet"] = next.toDictionary()
        }

        // Store timer context for sync
        lastTimerContext = payload

        // Send via message (immediate if reachable)
        sendMessage(payload)

        // Also use transferUserInfo for timer start/stop to ensure delivery
        if (isRunning && remainingSeconds == totalSeconds) || !isRunning {
            transferInfo(payload)
        }
    }

    // MARK: - Send Workout Completed

    func sendWorkoutCompleted(workout: WorkoutInfo, totalSetsCount: Int) {
        let payload: [String: Any] = [
            "type": "workoutCompleted",
            "workout": workout.toDictionary(),
            "totalSetsCount": totalSetsCount
        ]

        sendMessage(payload)
        updateApplicationContext(payload)
    }

    // MARK: - Send Workout Cleared

    func sendWorkoutCleared() {
        let payload: [String: Any] = [
            "type": "workoutCleared"
        ]

        sendMessage(payload)

        // Clear application context
        lastWorkoutContext = nil
        try? session?.updateApplicationContext([:])
    }

    // MARK: - Private Helpers

    private func sendMessage(_ message: [String: Any]) {
        guard let session = session, session.activationState == .activated else {
            return
        }

        // Try to send message if watch is reachable
        if session.isReachable {
            session.sendMessage(message, replyHandler: nil) { error in
                print("WatchConnectivity sendMessage error: \(error.localizedDescription)")
            }
        }
    }

    /// Transfer info is queued and delivered even when watch is not reachable
    private func transferInfo(_ info: [String: Any]) {
        guard let session = session, session.activationState == .activated else {
            return
        }
        session.transferUserInfo(info)
    }

    private func updateApplicationContext(_ context: [String: Any]) {
        guard let session = session, session.activationState == .activated else {
            return
        }

        lastWorkoutContext = context

        do {
            try session.updateApplicationContext(context)
        } catch {
            print("WatchConnectivity updateApplicationContext error: \(error.localizedDescription)")
        }
    }
}

// MARK: - WCSessionDelegate

extension PhoneSessionManager: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("WCSession activation failed: \(error.localizedDescription)")
        } else {
            print("WCSession activated with state: \(activationState.rawValue)")
        }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {
        print("WCSession became inactive")
    }

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        print("WCSession deactivated")
        // Reactivate session
        session.activate()
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        print("WCSession reachability changed: \(session.isReachable)")

        // When watch becomes reachable, send full current state
        if session.isReachable {
            Task { @MainActor in
                self.syncFullState()
            }
        }
    }
}

// MARK: - Data Transfer Objects

struct WorkoutInfo {
    let liftType: String
    let weekNumber: Int
    let cycleNumber: Int

    func toDictionary() -> [String: Any] {
        return [
            "liftType": liftType,
            "weekNumber": weekNumber,
            "cycleNumber": cycleNumber
        ]
    }

    static func from(_ workout: Workout) -> WorkoutInfo {
        return WorkoutInfo(
            liftType: workout.liftType.rawValue,
            weekNumber: workout.weekNumber,
            cycleNumber: workout.cycleNumber
        )
    }
}

struct SetInfo {
    let setNumber: Int
    let targetWeight: Double
    let targetReps: Int
    let isAMRAP: Bool
    let setType: String  // "Warmup", "Working", "BBB", "AMRAP"
    let plates: [Double]

    func toDictionary() -> [String: Any] {
        return [
            "setNumber": setNumber,
            "targetWeight": targetWeight,
            "targetReps": targetReps,
            "isAMRAP": isAMRAP,
            "setType": setType,
            "plates": plates
        ]
    }

    static func from(_ set: WorkoutSet, plates: [Double]) -> SetInfo {
        let setType: String
        if set.isAMRAP {
            setType = "AMRAP"
        } else if set.isWarmup {
            setType = "Warmup"
        } else if set.isBBB {
            setType = "BBB"
        } else {
            setType = "Working"
        }

        return SetInfo(
            setNumber: set.setNumber,
            targetWeight: set.targetWeight,
            targetReps: set.targetReps,
            isAMRAP: set.isAMRAP,
            setType: setType,
            plates: plates
        )
    }
}
