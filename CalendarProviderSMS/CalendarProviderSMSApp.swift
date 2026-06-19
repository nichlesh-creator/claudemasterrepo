import SwiftUI
import GoogleSignIn

@main
struct CalendarProviderSMSApp: App {
    @StateObject private var calendarService = GoogleCalendarService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(calendarService)
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}
