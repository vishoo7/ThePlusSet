import Foundation
import UserNotifications
import AudioToolbox

@MainActor
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    private init() {}

    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .sound, .badge]
            )
            return granted
        } catch {
            print("Notification permission error: \(error)")
            return false
        }
    }

    func scheduleRestTimerNotification(seconds: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Rest Complete"
        content.body = "Time to start your next set!"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(seconds),
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "restTimer",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    func cancelRestTimerNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["restTimer"]
        )
    }

    var chimeSoundID: SystemSoundID = 1016

    func triggerTimerCompletion() {
        AudioServicesPlaySystemSound(chimeSoundID)
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }

    func previewSound(_ soundID: SystemSoundID) {
        AudioServicesPlaySystemSound(soundID)
    }
}
