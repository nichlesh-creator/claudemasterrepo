import Foundation

struct CalendarEvent: Identifiable {
    let id: String
    let title: String
    let startDate: Date
    let endDate: Date
    let attendees: [Provider]
}

// MARK: - Google Calendar API Codable models

struct GoogleCalendarEventsResponse: Codable {
    let items: [GoogleCalendarEventItem]?
}

struct GoogleCalendarEventItem: Codable {
    let id: String
    let summary: String?
    let start: GoogleEventDateTime
    let end: GoogleEventDateTime
    let attendees: [GoogleAttendee]?
    let organizer: GoogleOrganizer?
}

struct GoogleEventDateTime: Codable {
    let dateTime: String?
    let date: String?

    var resolvedDate: Date? {
        if let dt = dateTime {
            return ISO8601DateFormatter().date(from: dt)
        }
        if let d = date {
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd"
            df.timeZone = .current
            return df.date(from: d)
        }
        return nil
    }
}

struct GoogleAttendee: Codable {
    let email: String
    let displayName: String?
    let responseStatus: String?
}

struct GoogleOrganizer: Codable {
    let email: String
    let displayName: String?
}

// MARK: - Google API error envelope

struct GoogleErrorResponse: Codable {
    let error: GoogleAPIError
}

struct GoogleAPIError: Codable {
    let code: Int
    let message: String
}
