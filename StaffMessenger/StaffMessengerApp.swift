import SwiftUI

@main
struct StaffMessengerApp: App {
    @StateObject private var calendarService = CalendarService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(calendarService)
        }
    }
}
