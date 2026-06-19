import Foundation

@MainActor
class CalendarService: ObservableObject {
    // @Published so ContentView re-renders when these change
    @Published var apiKey: String {
        didSet { UserDefaults.standard.set(apiKey, forKey: "calendarAPIKey") }
    }
    @Published var calendarID: String {
        didSet { UserDefaults.standard.set(calendarID, forKey: "calendarID") }
    }

    @Published var events: [CalendarEvent] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    var isConfigured: Bool {
        !apiKey.trimmingCharacters(in: .whitespaces).isEmpty &&
        !calendarID.trimmingCharacters(in: .whitespaces).isEmpty
    }

    init() {
        self.apiKey = UserDefaults.standard.string(forKey: "calendarAPIKey") ?? ""
        self.calendarID = UserDefaults.standard.string(forKey: "calendarID") ?? ""
    }

    func fetchEvents() async {
        guard isConfigured else {
            errorMessage = "Please enter your API key and calendar ID."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            events = try await loadCalendarEvents()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func loadCalendarEvents() async throws -> [CalendarEvent] {
        let trimmedID = calendarID.trimmingCharacters(in: .whitespaces)
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespaces)

        guard let encodedID = trimmedID.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            throw CalendarError.invalidCalendarID
        }

        var components = URLComponents()
        components.scheme = "https"
        components.host = "www.googleapis.com"
        components.path = "/calendar/v3/calendars/\(encodedID)/events"
        components.queryItems = [
            URLQueryItem(name: "key", value: trimmedKey),
            URLQueryItem(name: "timeMin", value: ISO8601DateFormatter().string(from: Date())),
            URLQueryItem(name: "timeMax", value: ISO8601DateFormatter().string(from: Date().addingTimeInterval(30 * 24 * 3600))),
            URLQueryItem(name: "singleEvents", value: "true"),
            URLQueryItem(name: "orderBy", value: "startTime"),
            URLQueryItem(name: "maxResults", value: "100")
        ]

        guard let url = components.url else { throw CalendarError.invalidCalendarID }

        let (data, response) = try await URLSession.shared.data(from: url)

        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            let message = (try? JSONDecoder().decode(GoogleErrorResponse.self, from: data))?.error.message
            throw CalendarError.apiError(http.statusCode, message)
        }

        let decoded = try JSONDecoder().decode(GoogleCalendarEventsResponse.self, from: data)

        return (decoded.items ?? []).compactMap { item -> CalendarEvent? in
            guard let startDate = item.start.resolvedDate,
                  let endDate = item.end.resolvedDate else { return nil }

            // Collect providers from attendees + organizer (deduplicated by email)
            var seen = Set<String>()
            var providers: [Provider] = []

            for attendee in item.attendees ?? [] {
                if seen.insert(attendee.email).inserted {
                    providers.append(Provider(email: attendee.email, displayName: attendee.displayName))
                }
            }

            if let org = item.organizer, seen.insert(org.email).inserted {
                providers.append(Provider(email: org.email, displayName: org.displayName))
            }

            guard !providers.isEmpty else { return nil }

            return CalendarEvent(
                id: item.id,
                title: item.summary ?? "Untitled Event",
                startDate: startDate,
                endDate: endDate,
                attendees: providers
            )
        }
    }
}

enum CalendarError: LocalizedError {
    case invalidCalendarID
    case apiError(Int, String?)

    var errorDescription: String? {
        switch self {
        case .invalidCalendarID:
            return "Invalid Calendar ID. Check the ID copied from Google Calendar settings."
        case .apiError(let code, let message):
            switch code {
            case 400: return "Bad request (400). \(message ?? "Check your Calendar ID.")"
            case 403: return "Access denied (403). Make sure the calendar is set to Public and your API key has Google Calendar API enabled."
            case 404: return "Calendar not found (404). Check your Calendar ID."
            default:  return "API error \(code). \(message ?? "")"
            }
        }
    }
}
