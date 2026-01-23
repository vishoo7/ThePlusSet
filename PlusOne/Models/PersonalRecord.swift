import Foundation
import SwiftData

@Model
final class PersonalRecord {
    var id: UUID = UUID()
    var liftTypeRaw: String
    var weight: Double
    var reps: Int
    var estimated1RM: Double
    var date: Date
    var workoutSetId: UUID?

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
