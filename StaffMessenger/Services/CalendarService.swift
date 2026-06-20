import Foundation
import Combine

@MainActor
class CalendarService: ObservableObject {

    // MARK: - Persisted settings

    @Published var apiKey: String {
        didSet { UserDefaults.standard.set(apiKey, forKey: "smAPIKey") }
    }
    @Published var calendarID: String {
        didSet { UserDefaults.standard.set(calendarID, forKey: "smCalendarID") }
    }
    @Published var coordinatorPhone: String {
        didSet { UserDefaults.standard.set(coordinatorPhone, forKey: "smCoordinatorPhone") }
    }
    /// Comma-separated phone numbers for non-iPhone (Android) users who receive a separate SMS
    @Published var nonIphonePhonesRaw: String {
        didSet { UserDefaults.standard.set(nonIphonePhonesRaw, forKey: "smNonIphonePhones") }
    }
    /// The user's own phone number — used to detect whether they are in the staffing group
    @Published var myPhoneNumber: String {
        didSet { UserDefaults.standard.set(myPhoneNumber, forKey: "smMyPhone") }
    }
    @Published var notificationsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(notificationsEnabled, forKey: "smNotificationsEnabled")
            NotificationService.scheduleDailyReminder(enabled: notificationsEnabled)
        }
    }
    /// Ordered list of event prefixes — defines which events count and their message order
    @Published var targetPrefixes: [String] {
        didSet { UserDefaults.standard.set(targetPrefixes.joined(separator: ","), forKey: "smPrefixes") }
    }

    // MARK: - State

    @Published var assignments: [StaffAssignment] = []
    /// Non-nil only on Thu/Fri → Monday transitions; holds today's E1W for the "Outgoing" line.
    @Published var outgoingE1W: StaffAssignment?
    @Published var isLoading    = false
    @Published var errorMessage: String?

    // MARK: - Derived

    var isConfigured: Bool {
        !apiKey.trimmingCharacters(in: .whitespaces).isEmpty &&
        !calendarID.trimmingCharacters(in: .whitespaces).isEmpty
    }

    /// BF1am presence is used as the "this is a staffing day" signal
    var isStaffingDay: Bool {
        assignments.contains { $0.prefix == "BF1am" }
    }

    var nonIphonePhones: [String] {
        nonIphonePhonesRaw
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    /// First weekday after today (skips Saturday and Sunday)
    var nextBusinessDay: Date {
        var date = Calendar.current.date(byAdding: .day, value: 1,
                                         to: Calendar.current.startOfDay(for: Date()))!
        while isWeekend(date) {
            date = Calendar.current.date(byAdding: .day, value: 1, to: date)!
        }
        return date
    }

    // MARK: - Init

    init() {
        self.apiKey               = UserDefaults.standard.string(forKey: "smAPIKey")               ?? ""
        self.calendarID           = UserDefaults.standard.string(forKey: "smCalendarID")           ?? ""
        self.coordinatorPhone     = UserDefaults.standard.string(forKey: "smCoordinatorPhone")     ?? ""
        self.nonIphonePhonesRaw   = UserDefaults.standard.string(forKey: "smNonIphonePhones")      ?? ""
        self.myPhoneNumber        = UserDefaults.standard.string(forKey: "smMyPhone")              ?? ""
        self.notificationsEnabled = UserDefaults.standard.bool(forKey: "smNotificationsEnabled")

        let saved = UserDefaults.standard.string(forKey: "smPrefixes") ?? ""
        if saved.isEmpty {
            self.targetPrefixes = ["E1W", "E1am", "OI-1", "Z1am", "BF1am", "BE1am", "EP1am"]
        } else {
            self.targetPrefixes = saved
                .components(separatedBy: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
        }
    }

    // MARK: - Fetch

    func fetchNextBusinessDayRoster() async {
        guard isConfigured else {
            errorMessage = "Please configure your API key and calendar ID in Settings."
            return
        }
        isLoading    = true
        errorMessage = nil
        do {
            assignments = try await loadEvents(for: nextBusinessDay)

            // On Thu/Fri → Monday: also fetch today's E1W so we can show
            // "E1W (Fri): outgoing" and "E1W (Mon): incoming" in the message.
            let cal = Calendar.current
            let todayWeekday  = cal.component(.weekday, from: Date())
            let targetWeekday = cal.component(.weekday, from: nextBusinessDay)
            if (todayWeekday == 5 || todayWeekday == 6) && targetWeekday == 2 {
                let todayEvents = try await loadEvents(for: cal.startOfDay(for: Date()))
                outgoingE1W = todayEvents.first { $0.prefix == "E1W" }
            } else {
                outgoingE1W = nil
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Private helpers

    private func loadEvents(for date: Date) async throws -> [StaffAssignment] {
        let cal = Calendar.current
        guard let start = cal.date(bySettingHour: 0,  minute: 0,  second: 0,  of: date),
              let end   = cal.date(bySettingHour: 23, minute: 59, second: 59, of: date) else { return [] }

        let fmt        = ISO8601DateFormatter()
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
            URLQueryItem(name: "timeMin",      value: fmt.string(from: start)),
            URLQueryItem(name: "timeMax",      value: fmt.string(from: end)),
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
        var prefixMap: [String: StaffAssignment] = [:]

        for event in decoded.items ?? [] {
            let title = event.summary ?? ""
            guard let matched = matchPrefix(in: title),
                  prefixMap[matched] == nil else { continue }
            let rawName     = extractBracketName(from: title) ?? title
            let displayName = formatDisplayName(rawName)
            prefixMap[matched] = StaffAssignment(prefix: matched, rawName: rawName, displayName: displayName)
        }

        return targetPrefixes.compactMap { prefixMap[$0] }
    }

    private func matchPrefix(in title: String) -> String? {
        let normalised = title.replacingOccurrences(of: "-", with: "").lowercased()
        for prefix in targetPrefixes.sorted(by: { $0.count > $1.count }) {
            let np = prefix.replacingOccurrences(of: "-", with: "").lowercased()
            if normalised.hasPrefix(np) {
                let rest = normalised.dropFirst(np.count)
                if rest.isEmpty || rest.first == " " || rest.first == "[" { return prefix }
            }
        }
        return nil
    }

    private func extractBracketName(from title: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: "\\[([^\\]]+)\\]") else { return nil }
        let ns      = title as NSString
        let matches = regex.matches(in: title, range: NSRange(location: 0, length: ns.length))
        guard let m = matches.first, m.numberOfRanges > 1 else { return nil }
        let r = m.range(at: 1)
        guard r.location != NSNotFound else { return nil }
        return ns.substring(with: r).trimmingCharacters(in: .whitespaces)
    }

    private func formatDisplayName(_ rawName: String) -> String {
        let parts = rawName.components(separatedBy: ", ")
        guard parts.count == 2 else { return rawName }
        return "\(parts[1].trimmingCharacters(in: .whitespaces)) \(parts[0].trimmingCharacters(in: .whitespaces))"
    }

    private func isWeekend(_ date: Date) -> Bool {
        let w = Calendar.current.component(.weekday, from: date)
        return w == 1 || w == 7  // 1 = Sunday, 7 = Saturday
    }
}

// MARK: - API Codable models

struct GoogleCalendarEventsResponse: Codable { let items: [GoogleCalendarEventItem]? }
struct GoogleCalendarEventItem:       Codable { let id: String; let summary: String? }
struct GoogleErrorResponse:           Codable { let error: GoogleAPIError }
struct GoogleAPIError:                Codable { let code: Int; let message: String }

enum CalendarError: LocalizedError {
    case invalidCalendarID
    case apiError(Int, String?)

    var errorDescription: String? {
        switch self {
        case .invalidCalendarID: return "Invalid Calendar ID."
        case .apiError(let code, let msg):
            switch code {
            case 403: return "Access denied (403). Make sure the calendar is public and your API key has Calendar API access."
            case 404: return "Calendar not found (404). Check your Calendar ID."
            default:  return "API error \(code). \(msg ?? "")"
            }
        }
    }
}
