import SwiftUI

struct ContentView: View {
    @EnvironmentObject var calendarService: GoogleCalendarService

    var body: some View {
        NavigationStack {
            if calendarService.isSignedIn {
                EventListView()
            } else {
                SignInView()
            }
        }
    }
}
