import UserNotifications

class NotificationService {
    static let shared = NotificationService()
    private init() {}

    private let center = UNUserNotificationCenter.current()

    private let reminders: [(id: String, hour: Int, minute: Int, title: String, body: String)] = [
        ("reminder-morning",  5, 30, "Morning Email Review",  "Review last night's emails and queue your draft replies."),
        ("reminder-afternoon", 14,  0, "Afternoon Check-in",    "New messages may be waiting — a good time to catch up."),
        ("reminder-evening",  18,  0, "End-of-Day Wrap-up",    "Review today's emails before you wrap up for the night.")
    ]

    // Request permission (no-op if already granted) then schedule all three.
    func requestPermissionAndSchedule() async {
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        guard granted else { return }
        schedule()
    }

    func schedule() {
        // Clear any previous versions of these reminders before re-adding
        center.removePendingNotificationRequests(withIdentifiers: reminders.map(\.id))

        for r in reminders {
            let content = UNMutableNotificationContent()
            content.title = r.title
            content.body  = r.body
            content.sound = .default

            var components = DateComponents()
            components.hour   = r.hour
            components.minute = r.minute

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let request = UNNotificationRequest(identifier: r.id, content: content, trigger: trigger)
            center.add(request)
        }
    }

    func cancel() {
        center.removePendingNotificationRequests(withIdentifiers: reminders.map(\.id))
    }
}
