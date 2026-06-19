import SwiftUI

struct EventListView: View {
    @EnvironmentObject var calendarService: CalendarService
    @State private var showSettings = false

    var body: some View {
        List {
            if calendarService.isLoading {
                HStack {
                    Spacer()
                    ProgressView("Loading events…")
                    Spacer()
                }
                .listRowSeparator(.hidden)
            } else if let error = calendarService.errorMessage {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                    .font(.callout)
                    .listRowSeparator(.hidden)
            } else if calendarService.events.isEmpty {
                ContentUnavailableView(
                    "No Events Found",
                    systemImage: "calendar.badge.exclamationmark",
                    description: Text("No upcoming events with providers in the next 30 days.")
                )
                .listRowSeparator(.hidden)
            } else {
                ForEach(calendarService.events) { event in
                    NavigationLink(destination: ProviderPickerView(event: event)) {
                        EventRow(event: event)
                    }
                }
            }
        }
        .navigationTitle("Upcoming Events")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gear")
                }
            }
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    Task { await calendarService.fetchEvents() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(calendarService.isLoading)
            }
        }
        .navigationDestination(isPresented: $showSettings) {
            SetupView()
        }
        .task {
            if calendarService.events.isEmpty {
                await calendarService.fetchEvents()
            }
        }
    }
}

private struct EventRow: View {
    let event: CalendarEvent

    private var dateText: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: event.startDate)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(event.title)
                .font(.headline)
                .lineLimit(1)
            Text(dateText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("\(event.attendees.count) provider\(event.attendees.count == 1 ? "" : "s")")
                .font(.caption)
                .foregroundStyle(.blue)
        }
        .padding(.vertical, 4)
    }
}
