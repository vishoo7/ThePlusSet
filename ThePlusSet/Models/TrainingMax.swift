import Foundation
import SwiftData

@Model
final class TrainingMax {
    var liftTypeRaw: String = "Squat"
    var weight: Double = 0
    var updatedAt: Date = Date()

    var liftType: LiftType {
        get { LiftType(rawValue: liftTypeRaw) ?? .squat }
        set { liftTypeRaw = newValue.rawValue }
    }

    init(liftType: LiftType, weight: Double) {
        self.liftTypeRaw = liftType.rawValue
        self.weight = weight
        self.updatedAt = Date()
    }
}
