import Foundation
import SwiftData

@Model
final class TrainingMax {
    var liftTypeRaw: String
    var weight: Double
    var updatedAt: Date

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
