import Foundation
import SwiftData

@Model
final class Workout {
    var id: UUID = UUID()
    var date: Date
    var liftTypeRaw: String
    var cycleNumber: Int
    var weekNumber: Int
    var notes: String = ""
    var isComplete: Bool = false

    @Relationship(deleteRule: .cascade, inverse: \WorkoutSet.workout)
    var sets: [WorkoutSet] = []

    var liftType: LiftType {
        get { LiftType(rawValue: liftTypeRaw) ?? .squat }
        set { liftTypeRaw = newValue.rawValue }
    }

    init(date: Date = Date(), liftType: LiftType, cycleNumber: Int, weekNumber: Int) {
        self.date = date
        self.liftTypeRaw = liftType.rawValue
        self.cycleNumber = cycleNumber
        self.weekNumber = weekNumber
    }

    var sortedSets: [WorkoutSet] {
        sets.sorted { $0.setNumber < $1.setNumber }
    }

    var mainSets: [WorkoutSet] {
        sortedSets.filter { !$0.isBBB }
    }

    var bbbSets: [WorkoutSet] {
        sortedSets.filter { $0.isBBB }
    }

    var amrapSet: WorkoutSet? {
        mainSets.first { $0.isAMRAP }
    }
}
