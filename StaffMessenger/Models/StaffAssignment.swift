import Foundation

struct StaffAssignment: Identifiable {
    let id = UUID()
    let prefix: String      // e.g. "E1am" — shown as the role label in the message
    let rawName: String     // e.g. "Chernin, Tyl" — as parsed from the calendar title
    var displayName: String // e.g. "Tyler Chernin" — updated from Contacts, falls back to formatted rawName
    var phoneNumber: String?

    var contactFound: Bool { phoneNumber != nil }
}
