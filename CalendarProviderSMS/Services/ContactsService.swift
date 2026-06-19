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

    func findPhoneNumber(for email: String) -> String? {
        let predicate = CNContact.predicateForContacts(matchingEmailAddress: email)
        let keys = [CNContactPhoneNumbersKey] as [CNKeyDescriptor]

        guard let contacts = try? store.unifiedContacts(matching: predicate, keysToFetch: keys),
              let contact = contacts.first,
              let phoneNumber = contact.phoneNumbers.first?.value else {
            return nil
        }

        return phoneNumber.stringValue
    }
}
