import SwiftUI

struct EventListView: View {
    @EnvironmentObject var calendarService: CalendarService
    @State private var showSettings = false
    @State private var showAllProviders = false

    // All unique providers across every event — deduplicated by name
    private var allProviders: [Provider] {
        var seen = Set<String>()
        return calendarService.events
            .flatMap { $0.attendees }
            .filter { seen.insert($0.name).inserted }
    }

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
        // "Message Everyone" button — shown when events are loaded
        .safeAreaInset(edge: .bottom) {
            if !calendarService.events.isEmpty && !calendarService.isLoading {
                Button {
                    showAllProviders = true
                } label: {
                    Label(
                        "Message All \(allProviders.count) Provider\(allProviders.count == 1 ? "" : "s")",
                        systemImage: "message.fill"
                    )
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding()
                .background(.regularMaterial)
            }
        }
        .navigationDestination(isPresented: $showSettings) {
            SetupView()
        }
        .navigationDestination(isPresented: $showAllProviders) {
            ProviderPickerView(title: "All Providers", providers: allProviders)
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
