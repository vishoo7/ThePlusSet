import Foundation
import SwiftData

@Model
final class AppSettings {
    var barWeight: Double = 45.0
    var availablePlates: [Double] = [45, 35, 25, 10, 5, 2.5]
    var bbbPercentage: Double = 0.50
    var mainSetRestSeconds: Int = 180
    var bbbSetRestSeconds: Int = 90
    var hasRequestedNotificationPermission: Bool = false
    var hasCompletedOnboarding: Bool = false

    init() {}

    init(
        barWeight: Double = 45.0,
        availablePlates: [Double] = [45, 35, 25, 10, 5, 2.5],
        bbbPercentage: Double = 0.50,
        mainSetRestSeconds: Int = 180,
        bbbSetRestSeconds: Int = 90
    ) {
        self.barWeight = barWeight
        self.availablePlates = availablePlates
        self.bbbPercentage = bbbPercentage
        self.mainSetRestSeconds = mainSetRestSeconds
        self.bbbSetRestSeconds = bbbSetRestSeconds
    }
}
