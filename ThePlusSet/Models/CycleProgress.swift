import Foundation
import SwiftData

@Model
final class CycleProgress {
    var cycleNumber: Int = 1
    var currentWeek: Int = 1  // 1-4
    var currentDay: Int = 0   // 0-3 (index into lift types)
    var startDate: Date = Date()

    init() {
        self.cycleNumber = 1
        self.currentWeek = 1
        self.currentDay = 0
        self.startDate = Date()
    }

    var weekDescription: String {
        switch currentWeek {
        case 1: return "Week 1: 5/5/5+"
        case 2: return "Week 2: 3/3/3+"
        case 3: return "Week 3: 5/3/1+"
        case 4: return "Week 4: Deload"
        default: return "Week \(currentWeek)"
        }
    }

    var currentLiftType: LiftType {
        // Default order - use liftType(for:) with settings for custom order
        let lifts: [LiftType] = [.squat, .bench, .deadlift, .overheadPress]
        return lifts[currentDay % 4]
    }

    func liftType(for settings: AppSettings) -> LiftType {
        let order = settings.exerciseOrder
        guard !order.isEmpty else {
            return currentLiftType
        }
        return order[currentDay % order.count]
    }

    func advanceToNextWorkout() {
        currentDay += 1
        if currentDay >= 4 {
            currentDay = 0
            currentWeek += 1
            if currentWeek > 4 {
                currentWeek = 1
                cycleNumber += 1
            }
        }
    }

    func resetCycle() {
        cycleNumber = 1
        currentWeek = 1
        currentDay = 0
        startDate = Date()
    }
}
