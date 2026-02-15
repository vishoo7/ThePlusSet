import Foundation
import SwiftData

@Model
final class AppSettings {
    var barWeight: Double = 45.0
    // Store plates as comma-separated string for SwiftData compatibility
    var availablePlatesString: String = "45,35,25,10,5,2.5"
    // Store exercise order as comma-separated string
    var exerciseOrderString: String = "squat,bench,deadlift,overheadPress"
    var bbbPercentage: Double = 0.50
    var trainingMaxPercentage: Double = 0.90  // TM = 1RM × this percentage
    var mainSetRestSeconds: Int = 180
    var bbbSetRestSeconds: Int = 90
    var warmupRestSeconds: Int = 60
    var hasRequestedNotificationPermission: Bool = false
    var hasCompletedOnboarding: Bool = false
    var hasPromptedForReview: Bool = false
    var bbbEnabled: Bool = true
    var timerChimeSoundID: Int = 1016  // System sound ID for timer completion

    var availablePlates: [Double] {
        get {
            availablePlatesString.split(separator: ",").compactMap { Double($0) }
        }
        set {
            availablePlatesString = newValue.map { String($0) }.joined(separator: ",")
        }
    }

    var exerciseOrder: [LiftType] {
        get {
            let names = exerciseOrderString.split(separator: ",").map { String($0) }
            return names.compactMap { name in
                switch name {
                case "squat": return .squat
                case "bench": return .bench
                case "deadlift": return .deadlift
                case "overheadPress": return .overheadPress
                default: return nil
                }
            }
        }
        set {
            exerciseOrderString = newValue.map { lift in
                switch lift {
                case .squat: return "squat"
                case .bench: return "bench"
                case .deadlift: return "deadlift"
                case .overheadPress: return "overheadPress"
                }
            }.joined(separator: ",")
        }
    }

    init() {}

    init(
        barWeight: Double = 45.0,
        availablePlates: [Double] = [45, 35, 25, 10, 5, 2.5],
        bbbPercentage: Double = 0.50,
        trainingMaxPercentage: Double = 0.90,
        mainSetRestSeconds: Int = 180,
        bbbSetRestSeconds: Int = 90,
        warmupRestSeconds: Int = 60
    ) {
        self.barWeight = barWeight
        self.availablePlatesString = availablePlates.map { String($0) }.joined(separator: ",")
        self.bbbPercentage = bbbPercentage
        self.trainingMaxPercentage = trainingMaxPercentage
        self.mainSetRestSeconds = mainSetRestSeconds
        self.bbbSetRestSeconds = bbbSetRestSeconds
        self.warmupRestSeconds = warmupRestSeconds
    }
}
