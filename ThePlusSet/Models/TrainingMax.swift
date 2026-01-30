import Foundation
import SwiftData

@Model
final class TrainingMax {
    var liftTypeRaw: String = "Squat"
    var weight: Double = 0  // Training max (used for calculations)
    var oneRepMax: Double?  // User's actual 1RM (for display purposes)
    var updatedAt: Date = Date()

    var liftType: LiftType {
        get { LiftType(rawValue: liftTypeRaw) ?? .squat }
        set { liftTypeRaw = newValue.rawValue }
    }

    init(liftType: LiftType, weight: Double, oneRepMax: Double? = nil) {
        self.liftTypeRaw = liftType.rawValue
        self.weight = weight
        self.oneRepMax = oneRepMax
        self.updatedAt = Date()
    }
}
