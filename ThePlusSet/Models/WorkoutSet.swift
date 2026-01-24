import Foundation
import SwiftData

@Model
final class WorkoutSet {
    var id: UUID = UUID()
    var setNumber: Int = 0
    var targetWeight: Double = 0
    var targetReps: Int = 0
    var actualReps: Int? = nil
    var isAMRAP: Bool = false
    var isBBB: Bool = false
    var isWarmup: Bool = false
    var isComplete: Bool = false
    var completedAt: Date? = nil
    var workout: Workout? = nil

    init(
        setNumber: Int,
        targetWeight: Double,
        targetReps: Int,
        isAMRAP: Bool = false,
        isBBB: Bool = false,
        isWarmup: Bool = false
    ) {
        self.setNumber = setNumber
        self.targetWeight = targetWeight
        self.targetReps = targetReps
        self.isAMRAP = isAMRAP
        self.isBBB = isBBB
        self.isWarmup = isWarmup
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
