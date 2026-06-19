import Foundation
import UIKit
import GoogleSignIn

@MainActor
class GoogleCalendarService: ObservableObject {
    @Published var isSignedIn = false
    @Published var events: [CalendarEvent] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let calendarScope = "https://www.googleapis.com/auth/calendar.readonly"

    init() {
        GIDSignIn.sharedInstance.restorePreviousSignIn { [weak self] user, _ in
            DispatchQueue.main.async {
                self?.isSignedIn = user != nil
            }
        }
    }

    func signIn() async {
        guard let rootVC = rootViewController() else {
            errorMessage = "Could not find root view controller."
            return
        }
        do {
            _ = try await GIDSignIn.sharedInstance.signIn(
                withPresenting: rootVC,
                hint: nil,
                additionalScopes: [calendarScope]
            )
            isSignedIn = true
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        isSignedIn = false
        events = []
    }

    func fetchEvents() async {
        guard let user = GIDSignIn.sharedInstance.currentUser else {
            errorMessage = "Not signed in."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            try await user.refreshTokensIfNeeded()
            let token = user.accessToken.tokenString
            events = try await fetchCalendarEvents(token: token)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func fetchCalendarEvents(token: String) async throws -> [CalendarEvent] {
        let formatter = ISO8601DateFormatter()
        let now = formatter.string(from: Date())
        let future = formatter.string(from: Date().addingTimeInterval(30 * 24 * 3600))

        var components = URLComponents(string: "https://www.googleapis.com/calendar/v3/calendars/primary/events")!
        components.queryItems = [
            URLQueryItem(name: "timeMin", value: now),
            URLQueryItem(name: "timeMax", value: future),
            URLQueryItem(name: "singleEvents", value: "true"),
            URLQueryItem(name: "orderBy", value: "startTime"),
            URLQueryItem(name: "maxResults", value: "100")
        ]

        var request = URLRequest(url: components.url!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            throw CalendarError.apiError(http.statusCode)
        }

        let decoded = try JSONDecoder().decode(GoogleCalendarEventsResponse.self, from: data)

        return decoded.items.compactMap { item -> CalendarEvent? in
            guard let startDate = item.start.resolvedDate,
                  let endDate = item.end.resolvedDate,
                  let rawAttendees = item.attendees else { return nil }

            let providers = rawAttendees
                .filter { $0.self != true }
                .map { Provider(email: $0.email, displayName: $0.displayName) }

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

    private func rootViewController() -> UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .rootViewController
    }
}

enum CalendarError: LocalizedError {
    case apiError(Int)

    var errorDescription: String? {
        switch self {
        case .apiError(let code): return "Google Calendar API returned HTTP \(code). Check your OAuth scopes."
        }
    }
}
