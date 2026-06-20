import Contacts

actor ContactsService {
    static let shared = ContactsService()

    private let store = CNContactStore()

    func requestAccess() async -> Bool {
        let status = CNContactStore.authorizationStatus(for: .contacts)
        if status == .authorized { return true }
        if status != .notDetermined { return false }

        return await withCheckedContinuation { continuation in
            store.requestAccess(for: .contacts) { granted, _ in
                continuation.resume(returning: granted)
            }
        }
    }

    // Look up by email address (for attendees returned by the Calendar API)
    func findPhoneNumber(forEmail email: String) -> String? {
        let predicate = CNContact.predicateForContacts(matchingEmailAddress: email)
        let keys = [CNContactPhoneNumbersKey] as [CNKeyDescriptor]

        guard let contacts = try? store.unifiedContacts(matching: predicate, keysToFetch: keys),
              let phoneNumber = contacts.first?.phoneNumbers.first?.value else { return nil }

        return phoneNumber.stringValue
    }

    // Look up by name for providers parsed from event titles (e.g. "Chernin, Tyl")
    // Handles "LastName, FirstName" format common in medical scheduling systems
    func findPhoneNumber(forName fullName: String) -> String? {
        let parts = fullName.components(separatedBy: ", ")
        let lastName = parts[0].trimmingCharacters(in: .whitespaces)
        let firstName = parts.count > 1 ? parts[1].trimmingCharacters(in: .whitespaces) : nil

        let predicate = CNContact.predicateForContacts(matchingName: lastName)
        let keys = [
            CNContactPhoneNumbersKey,
            CNContactGivenNameKey,
            CNContactFamilyNameKey
        ] as [CNKeyDescriptor]

        guard let contacts = try? store.unifiedContacts(matching: predicate, keysToFetch: keys),
              !contacts.isEmpty else { return nil }

        // If a first name / initial is available, prefer the closest match
        let best: CNContact?
        if let firstName {
            best = contacts.first {
                $0.givenName.lowercased().hasPrefix(firstName.lowercased()) ||
                firstName.lowercased().hasPrefix($0.givenName.lowercased())
            } ?? contacts.first
        } else {
            best = contacts.first
        }

        return best?.phoneNumbers.first?.value.stringValue
    }
}
