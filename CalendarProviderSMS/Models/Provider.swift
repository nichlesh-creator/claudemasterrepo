import Foundation

struct Provider: Identifiable {
    let id: UUID
    let name: String
    let email: String
    var phoneNumber: String?
    var isSelected: Bool = false

    init(email: String, displayName: String?) {
        self.id = UUID()
        self.email = email
        self.name = displayName?.isEmpty == false ? displayName! : email
    }
}
