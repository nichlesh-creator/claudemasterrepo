import Foundation
import Combine

@MainActor
class CalendarService: ObservableObject {
    @Published var apiKey: String {
        didSet { UserDefaults.standard.set(apiKey, forKey: "smAPIKey") }
    }
    @Published var calendarID: String {
        didSet { UserDefaults.standard.set(calendarID, forKey: "smCalendarID") }
    }
    @Published var coordinatorPhone: String {
        didSet { UserDefaults.standard.set(coordinatorPhone, forKey: "smCoordinatorPhone") }
    }
    // Ordered list of event prefixes to match — defines both which events count and message order
    @Published var targetPrefixes: [String] {
        didSet { UserDefaults.standard.set(targetPrefixes.joined(separator: ","), forKey: "smPrefixes") }
    }

    @Published var assignments: [StaffAssignment] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    var isConfigured: Bool {
        !apiKey.trimmingCharacters(in: .whitespaces).isEmpty &&
        !calendarID.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var tomorrowDate: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: Date())) ?? Date()
    }

    init() {
        self.apiKey          = UserDefaults.standard.string(forKey: "smAPIKey") ?? ""
        self.calendarID      = UserDefaults.standard.string(forKey: "smCalendarID") ?? ""
        self.coordinatorPhone = UserDefaults.standard.string(forKey: "smCoordinatorPhone") ?? ""

        let saved = UserDefaults.standard.string(forKey: "smPrefixes") ?? ""
        if saved.isEmpty {
            self.targetPrefixes = ["E1W", "E1am", "OI-1", "Z1am", "BF1am", "BE1am", "EP1am"]
        } else {
            self.targetPrefixes = saved.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        }
    }

    func fetchTomorrowsRoster() async {
        guard isConfigured else {
            errorMessage = "Please configure your API key and calendar ID in Settings."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            assignments = try await loadEvents(for: tomorrowDate)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func loadEvents(for date: Date) async throws -> [StaffAssignment] {
        let cal = Calendar.current
        guard let startOfDay = cal.date(bySettingHour: 0,  minute: 0,  second: 0,  of: date),
              let endOfDay   = cal.date(bySettingHour: 23, minute: 59, second: 59, of: date) else { return [] }

        let fmt = ISO8601DateFormatter()
        let trimmedID  = calendarID.trimmingCharacters(in: .whitespaces)
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespaces)

        guard let encodedID = trimmedID.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            throw CalendarError.invalidCalendarID
        }

        var components = URLComponents()
        components.scheme = "https"
        components.host   = "www.googleapis.com"
        components.path   = "/calendar/v3/calendars/\(encodedID)/events"
        components.queryItems = [
            URLQueryItem(name: "key",          value: trimmedKey),
            URLQueryItem(name: "timeMin",      value: fmt.string(from: startOfDay)),
            URLQueryItem(name: "timeMax",      value: fmt.string(from: endOfDay)),
            URLQueryItem(name: "singleEvents", value: "true"),
            URLQueryItem(name: "maxResults",   value: "200")
        ]

        guard let url = components.url else { throw CalendarError.invalidCalendarID }

        let (data, response) = try await URLSession.shared.data(from: url)

        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            let msg = (try? JSONDecoder().decode(GoogleErrorResponse.self, from: data))?.error.message
            throw CalendarError.apiError(http.statusCode, msg)
        }

        let decoded = try JSONDecoder().decode(GoogleCalendarEventsResponse.self, from: data)
        let events = decoded.items ?? []

        // Map each target prefix to the first matching event
        var prefixMap: [String: StaffAssignment] = [:]
        for event in events {
            let title = event.summary ?? ""
            guard let matched = matchPrefix(in: title),
                  prefixMap[matched] == nil else { continue }
            let rawName     = extractBracketName(from: title) ?? title
            let displayName = formatDisplayName(rawName)
            prefixMap[matched] = StaffAssignment(prefix: matched, rawName: rawName, displayName: displayName)
        }

        // Return in the configured prefix order, skipping any not found
        return targetPrefixes.compactMap { prefixMap[$0] }
    }

    // Match event title against target prefixes.
    // Normalises hyphens so "E1-am" matches "E1am". Checks longer prefixes first.
    private func matchPrefix(in title: String) -> String? {
        let normalised = title.replacingOccurrences(of: "-", with: "").lowercased()
        for prefix in targetPrefixes.sorted(by: { $0.count > $1.count }) {
            let np = prefix.replacingOccurrences(of: "-", with: "").lowercased()
            if normalised.hasPrefix(np) {
                let rest = normalised.dropFirst(np.count)
                if rest.isEmpty || rest.first == " " || rest.first == "[" {
                    return prefix
                }
            }
        }
        return nil
    }

    // "E1am [Chernin, Tyl]" → "Chernin, Tyl"
    private func extractBracketName(from title: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: "\\[([^\\]]+)\\]") else { return nil }
        let ns = title as NSString
        let matches = regex.matches(in: title, range: NSRange(location: 0, length: ns.length))
        guard let m = matches.first, m.numberOfRanges > 1 else { return nil }
        let r = m.range(at: 1)
        guard r.location != NSNotFound else { return nil }
        return ns.substring(with: r).trimmingCharacters(in: .whitespaces)
    }

    // "Chernin, Tyl" → "Tyl Chernin" (used as fallback before Contacts lookup)
    private func formatDisplayName(_ rawName: String) -> String {
        let parts = rawName.components(separatedBy: ", ")
        guard parts.count == 2 else { return rawName }
        return "\(parts[1].trimmingCharacters(in: .whitespaces)) \(parts[0].trimmingCharacters(in: .whitespaces))"
    }
}

// MARK: - Google Calendar API Codable models

struct GoogleCalendarEventsResponse: Codable {
    let items: [GoogleCalendarEventItem]?
}

struct GoogleCalendarEventItem: Codable {
    let id: String
    let summary: String?
}

struct GoogleErrorResponse: Codable {
    let error: GoogleAPIError
}

struct GoogleAPIError: Codable {
    let code: Int
    let message: String
}

enum CalendarError: LocalizedError {
    case invalidCalendarID
    case apiError(Int, String?)

    var errorDescription: String? {
        switch self {
        case .invalidCalendarID:
            return "Invalid Calendar ID. Check the ID copied from Google Calendar settings."
        case .apiError(let code, let msg):
            switch code {
            case 403: return "Access denied (403). Make sure the calendar is public and your API key has Calendar API access."
            case 404: return "Calendar not found (404). Check your Calendar ID."
            default:  return "API error \(code). \(msg ?? "")"
            }
        }
    }
}
