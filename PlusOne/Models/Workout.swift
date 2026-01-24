import Foundation
import SwiftData

@Model
final class Workout {
    var id: UUID = UUID()
    var date: Date = Date()
    var liftTypeRaw: String = "Squat"
    var cycleNumber: Int = 1
    var weekNumber: Int = 1
    var notes: String = ""
    var isComplete: Bool = false

    @Relationship(deleteRule: .cascade, inverse: \WorkoutSet.workout)
    var sets: [WorkoutSet]? = []

    var liftType: LiftType {
        get { LiftType(rawValue: liftTypeRaw) ?? .squat }
        set { liftTypeRaw = newValue.rawValue }
    }

    init(date: Date = Date(), liftType: LiftType, cycleNumber: Int, weekNumber: Int) {
        self.date = date
        self.liftTypeRaw = liftType.rawValue
        self.cycleNumber = cycleNumber
        self.weekNumber = weekNumber
        self.sets = []
    }

    var sortedSets: [WorkoutSet] {
        (sets ?? []).sorted { $0.setNumber < $1.setNumber }
    }

    var warmupSets: [WorkoutSet] {
        sortedSets.filter { $0.isWarmup }
    }

    var mainSets: [WorkoutSet] {
        sortedSets.filter { !$0.isBBB && !$0.isWarmup }
    }

    var bbbSets: [WorkoutSet] {
        sortedSets.filter { $0.isBBB }
    }

    var amrapSet: WorkoutSet? {
        mainSets.first { $0.isAMRAP }
    }

    func addSet(_ set: WorkoutSet) {
        if sets == nil {
            sets = []
        }
        sets?.append(set)
    }
}
