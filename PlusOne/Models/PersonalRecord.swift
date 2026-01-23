import Foundation
import SwiftData

@Model
final class PersonalRecord {
    var id: UUID = UUID()
    var liftTypeRaw: String = "Squat"
    var weight: Double = 0
    var reps: Int = 0
    var estimated1RM: Double = 0
    var date: Date = Date()
    var workoutSetId: UUID? = nil

    var liftType: LiftType {
        get { LiftType(rawValue: liftTypeRaw) ?? .squat }
        set { liftTypeRaw = newValue.rawValue }
    }

    init(liftType: LiftType, weight: Double, reps: Int, date: Date = Date(), workoutSetId: UUID? = nil) {
        self.liftTypeRaw = liftType.rawValue
        self.weight = weight
        self.reps = reps
        self.estimated1RM = WendlerCalculator.estimatedOneRepMax(weight: weight, reps: reps)
        self.date = date
        self.workoutSetId = workoutSetId
    }
}
