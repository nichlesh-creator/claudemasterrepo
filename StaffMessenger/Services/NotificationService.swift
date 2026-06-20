import UserNotifications

struct NotificationService {
    private static let identifier = "staffing-reminder"

    static func requestPermission() async {
        _ = try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge])
    }

    // Schedules (or cancels) a daily notification at 7:45 am.
    static func scheduleDailyReminder(enabled: Bool) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        guard enabled else { return }

        let content = UNMutableNotificationContent()
        content.title = "Send Today's Staffing Message"
        content.body  = "Tap to review and send the staffing message."
        content.sound = .default

        var components      = DateComponents()
        components.hour     = 7
        components.minute   = 45

        let trigger = UNCalendarNotificationTrigger(dateMatchingComponents: components, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        center.add(request)
    }
}
