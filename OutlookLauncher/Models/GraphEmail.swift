import Foundation

struct GraphEmail: Identifiable, Codable {
    let id: String
    let subject: String?
    let from: Sender?
    let bodyPreview: String?
    let receivedDateTime: String?

    var fromName: String { from?.emailAddress?.name ?? "Unknown" }
    var fromAddress: String { from?.emailAddress?.address ?? "" }
    var displaySubject: String { subject ?? "(No subject)" }
    var displayPreview: String { bodyPreview ?? "" }

    struct Sender: Codable {
        let emailAddress: Contact?
        struct Contact: Codable {
            let name: String?
            let address: String?
        }
    }
}

struct GraphMailResponse: Codable {
    let value: [GraphEmail]
}
