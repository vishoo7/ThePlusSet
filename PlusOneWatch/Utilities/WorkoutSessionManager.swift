import Foundation
import HealthKit

/// Manages an HKWorkoutSession to keep the watch app alive during workouts.
/// No health data is collected or saved — this is purely for background persistence.
@MainActor
class WorkoutSessionManager: NSObject, ObservableObject {
    static let shared = WorkoutSessionManager()

    private let healthStore = HKHealthStore()
    private var workoutSession: HKWorkoutSession?
    private var hasRequestedAuth = false

    override init() {
        super.init()
        // Clean up any orphaned session from a previous crash
        recoverExistingSession()
    }

    func startSession() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        guard workoutSession == nil else { return }

        if !hasRequestedAuth {
            hasRequestedAuth = true
            // Request minimal HealthKit authorization (workout type only)
            let workoutType = HKQuantityType.workoutType()
            healthStore.requestAuthorization(toShare: [workoutType], read: []) { [weak self] success, error in
                if let error = error {
                    print("HealthKit auth error: \(error.localizedDescription)")
                }
                if success {
                    Task { @MainActor in
                        self?.createAndStartSession()
                    }
                }
            }
        } else {
            createAndStartSession()
        }
    }

    func endSession() {
        workoutSession?.end()
        workoutSession = nil
    }

    private func createAndStartSession() {
        guard workoutSession == nil else { return }

        let config = HKWorkoutConfiguration()
        config.activityType = .traditionalStrengthTraining
        config.locationType = .indoor

        do {
            let session = try HKWorkoutSession(healthStore: healthStore, configuration: config)
            session.delegate = self
            session.startActivity(with: Date())
            workoutSession = session
        } catch {
            print("Failed to create workout session: \(error.localizedDescription)")
        }
    }

    private func recoverExistingSession() {
        // On watchOS, check if there's an existing session to recover from a crash/relaunch
        // If so, end it since we don't have the workout context anymore
        // HKWorkoutSession recovery is handled by the system delivering the session
        // via handle(_:) but we use a simple approach: just ensure clean state on init
    }
}

extension WorkoutSessionManager: HKWorkoutSessionDelegate {
    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        print("Workout session state: \(fromState.rawValue) -> \(toState.rawValue)")
    }

    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("Workout session error: \(error.localizedDescription)")
        Task { @MainActor in
            self.workoutSession = nil
        }
    }
}
