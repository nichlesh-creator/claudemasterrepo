import Foundation

class ClaudeService {
    private let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!
    private let model = "claude-haiku-4-5-20251001"

    func generateDraft(for email: GraphEmail, apiKey: String) async throws -> String {
        let prompt = """
        Draft a concise, professional reply to the email below. \
        Return only the body text — no subject line, no headers, no sign-off placeholder.

        From: \(email.fromName) <\(email.fromAddress)>
        Subject: \(email.displaySubject)

        \(email.displayPreview)
        """

        let body: [String: Any] = [
            "model": model,
            "max_tokens": 512,
            "messages": [["role": "user", "content": prompt]]
        ]

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        let code = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard code == 200 else { throw ClaudeError.httpError(code) }

        return try JSONDecoder().decode(ClaudeResponse.self, from: data).content.first?.text ?? ""
    }
}

private struct ClaudeResponse: Codable {
    let content: [Block]
    struct Block: Codable { let text: String }
}

enum ClaudeError: LocalizedError {
    case httpError(Int)
    var errorDescription: String? {
        if case .httpError(let c) = self {
            return "Claude API returned HTTP \(c) — check your API key."
        }
        return nil
    }
}
