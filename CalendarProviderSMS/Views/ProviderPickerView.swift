import SwiftUI

struct ProviderPickerView: View {
    let event: CalendarEvent

    @State private var providers: [Provider] = []
    @State private var isLoadingContacts = true
    @State private var contactsAccessDenied = false
    @State private var navigateToCompose = false

    private var selectedProviders: [Provider] {
        providers.filter { $0.isSelected && $0.phoneNumber != nil }
    }

    var body: some View {
        List {
            if isLoadingContacts {
                HStack {
                    Spacer()
                    ProgressView("Looking up phone numbers...")
                    Spacer()
                }
                .listRowSeparator(.hidden)
            } else {
                if contactsAccessDenied {
                    Label(
                        "Contacts access denied. Go to Settings > Privacy > Contacts to enable auto-lookup.",
                        systemImage: "exclamationmark.triangle.fill"
                    )
                    .foregroundStyle(.orange)
                    .font(.callout)
                    .listRowSeparator(.hidden)
                }

                ForEach($providers) { $provider in
                    ProviderRow(provider: $provider)
                }
            }
        }
        .navigationTitle(event.title)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Button {
                navigateToCompose = true
            } label: {
                Label(
                    "Compose SMS (\(selectedProviders.count) selected)",
                    systemImage: "message.fill"
                )
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(selectedProviders.isEmpty ? Color.gray : Color.blue)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(selectedProviders.isEmpty)
            .padding()
            .background(.regularMaterial)
        }
        .navigationDestination(isPresented: $navigateToCompose) {
            ComposeMessageView(providers: selectedProviders)
        }
        .task {
            await loadPhoneNumbers()
        }
    }

    private func loadPhoneNumbers() async {
        let hasAccess = await ContactsService.shared.requestAccess()
        contactsAccessDenied = !hasAccess

        var loaded = event.attendees

        if hasAccess {
            for i in loaded.indices {
                if let email = loaded[i].email {
                    loaded[i].phoneNumber = await ContactsService.shared.findPhoneNumber(forEmail: email)
                } else {
                    loaded[i].phoneNumber = await ContactsService.shared.findPhoneNumber(forName: loaded[i].name)
                }
                loaded[i].isSelected = loaded[i].phoneNumber != nil
            }
        }

        providers = loaded
        isLoadingContacts = false
    }
}

private struct ProviderRow: View {
    @Binding var provider: Provider

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(provider.name)
                    .font(.body)
                if let email = provider.email {
                    Text(email)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let phone = provider.phoneNumber {
                    Text(phone)
                        .font(.caption)
                        .foregroundStyle(.green)
                } else {
                    Text("No phone number in Contacts")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            Spacer()

            if provider.phoneNumber != nil {
                Toggle("", isOn: $provider.isSelected)
                    .labelsHidden()
            }
        }
        .opacity(provider.phoneNumber == nil ? 0.5 : 1.0)
        .contentShape(Rectangle())
        .onTapGesture {
            if provider.phoneNumber != nil {
                provider.isSelected.toggle()
            }
        }
    }
}
