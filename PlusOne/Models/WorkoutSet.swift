import Foundation
import SwiftData

@Model
final class WorkoutSet {
    var id: UUID = UUID()
    var setNumber: Int
    var targetWeight: Double
    var targetReps: Int
    var actualReps: Int?
    var isAMRAP: Bool = false
    var isBBB: Bool = false
    var isComplete: Bool = false
    var completedAt: Date?
    var workout: Workout?

    init(
        setNumber: Int,
        targetWeight: Double,
        targetReps: Int,
        isAMRAP: Bool = false,
        isBBB: Bool = false
    ) {
        self.setNumber = setNumber
        self.targetWeight = targetWeight
        self.targetReps = targetReps
        self.isAMRAP = isAMRAP
        self.isBBB = isBBB
    }

    func complete(reps: Int) {
        self.actualReps = reps
        self.isComplete = true
        self.completedAt = Date()
    }

    var repDisplay: String {
        if isAMRAP {
            return "\(targetReps)+"
        }
        return "\(targetReps)"
    }
}
