import Contacts

actor ContactsService {
    static let shared = ContactsService()
    private let store = CNContactStore()

    func requestAccess() async -> Bool {
        let status = CNContactStore.authorizationStatus(for: .contacts)
        if status == .authorized { return true }
        if status != .notDetermined { return false }
        return await withCheckedContinuation { cont in
            store.requestAccess(for: .contacts) { granted, _ in cont.resume(returning: granted) }
        }
    }

    // Look up by "LastName, FirstName" format.
    // Returns the contact's full formatted name (from Contacts) and phone number.
    func lookup(rawName: String) -> (displayName: String, phone: String?)? {
        let parts = rawName.components(separatedBy: ", ")
        let lastName  = parts[0].trimmingCharacters(in: .whitespaces)
        let firstName = parts.count > 1 ? parts[1].trimmingCharacters(in: .whitespaces) : nil

        let predicate = CNContact.predicateForContacts(matchingName: lastName)
        let keys = [
            CNContactGivenNameKey,
            CNContactFamilyNameKey,
            CNContactPhoneNumbersKey
        ] as [CNKeyDescriptor]

        guard let contacts = try? store.unifiedContacts(matching: predicate, keysToFetch: keys),
              !contacts.isEmpty else { return nil }

        // Prefer contact whose given name starts with the calendar first name / initial
        let best: CNContact?
        if let firstName {
            best = contacts.first {
                $0.givenName.lowercased().hasPrefix(firstName.lowercased()) ||
                firstName.lowercased().hasPrefix($0.givenName.lowercased())
            } ?? contacts.first
        } else {
            best = contacts.first
        }

        guard let contact = best else { return nil }

        let fullName = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
        let phone    = contact.phoneNumbers.first?.value.stringValue
        return (displayName: fullName.isEmpty ? rawName : fullName, phone: phone)
    }
}
