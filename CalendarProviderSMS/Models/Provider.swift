import Foundation

struct Provider: Identifiable {
    let id: UUID
    let name: String
    let email: String?      // nil when extracted from event title
    var phoneNumber: String?
    var isSelected: Bool = false

    // For attendees/organizers that come with an email address
    init(email: String, displayName: String?) {
        self.id = UUID()
        self.email = email
        self.name = displayName?.isEmpty == false ? displayName! : email
    }

    // For providers whose name is parsed from the event title (e.g. "[Chernin, Tyl]")
    init(name: String) {
        self.id = UUID()
        self.name = name
        self.email = nil
    }
}
