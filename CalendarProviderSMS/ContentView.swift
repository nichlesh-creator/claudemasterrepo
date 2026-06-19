import SwiftUI

struct ContentView: View {
    @EnvironmentObject var calendarService: CalendarService

    var body: some View {
        NavigationStack {
            if calendarService.isConfigured {
                EventListView()
            } else {
                SetupView()
            }
        }
    }
}
