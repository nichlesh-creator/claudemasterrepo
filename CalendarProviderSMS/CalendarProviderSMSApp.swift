import SwiftUI

@main
struct CalendarProviderSMSApp: App {
    @StateObject private var calendarService = CalendarService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(calendarService)
        }
    }
}
