import Foundation

class GraphEmailService {
    // Fetch emails received in the last 12 hours
    func fetchRecentEmails(accessToken: String) async throws -> [GraphEmail] {
        let since = Date().addingTimeInterval(-12 * 3600)
        let formatter = ISO8601DateFormatter()
        let filter = "receivedDateTime ge \(formatter.string(from: since))"

        var components = URLComponents(string: "https://graph.microsoft.com/v1.0/me/messages")!
        components.queryItems = [
            URLQueryItem(name: "$filter", value: filter),
            URLQueryItem(name: "$select", value: "id,subject,from,bodyPreview,receivedDateTime"),
            URLQueryItem(name: "$orderby", value: "receivedDateTime desc"),
            URLQueryItem(name: "$top", value: "25")
        ]

        var request = URLRequest(url: components.url!)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        try assertHTTP(response, expected: 200)
        return try JSONDecoder().decode(GraphMailResponse.self, from: data).value
    }

    // Create a reply draft — never sends automatically
    func createDraft(body: String, replyingTo email: GraphEmail, accessToken: String) async throws {
        let payload: [String: Any] = [
            "subject": "Re: \(email.displaySubject)",
            "body": ["contentType": "Text", "content": body],
            "toRecipients": [["emailAddress": ["name": email.fromName, "address": email.fromAddress]]],
            "isDraft": true
        ]

        var request = URLRequest(url: URL(string: "https://graph.microsoft.com/v1.0/me/messages")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (_, response) = try await URLSession.shared.data(for: request)
        try assertHTTP(response, expected: 201)
    }

    private func assertHTTP(_ response: URLResponse, expected: Int) throws {
        let code = (response as? HTTPURLResponse)?.statusCode ?? 0
        if code != expected {
            throw GraphError.httpError(code)
        }
    }
}

enum GraphError: LocalizedError {
    case httpError(Int)
    var errorDescription: String? {
        if case .httpError(let c) = self { return "Microsoft Graph returned HTTP \(c)" }
        return nil
    }
}
