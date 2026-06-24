import SwiftUI

struct EmailListView: View {
    @EnvironmentObject var authService: AuthService
    @AppStorage("anthropicApiKey") private var anthropicKey = ""

    @State private var emails: [GraphEmail] = []
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var selectedEmail: GraphEmail?

    private let emailService = GraphEmailService()

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading emails…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if !errorMessage.isEmpty {
                    ContentUnavailableView(
                        "Could not load emails",
                        systemImage: "exclamationmark.triangle",
                        description: Text(errorMessage)
                    )
                } else if emails.isEmpty {
                    ContentUnavailableView(
                        "No Recent Emails",
                        systemImage: "tray",
                        description: Text("No messages received in the last 12 hours.")
                    )
                } else {
                    List(emails) { email in
                        Button { selectedEmail = email } label: {
                            EmailRowView(email: email)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("Last Night's Emails")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        Task { await loadEmails() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(isLoading)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Sign Out") { authService.signOut() }
                }
            }
            .sheet(item: $selectedEmail) { email in
                EmailDetailView(email: email, anthropicApiKey: anthropicKey)
                    .environmentObject(authService)
            }
            .task { await loadEmails() }
        }
    }

    private func loadEmails() async {
        guard let token = authService.accessToken else { return }
        isLoading = true
        errorMessage = ""
        do {
            emails = try await emailService.fetchRecentEmails(accessToken: token)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

struct EmailRowView: View {
    let email: GraphEmail

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(email.fromName)
                .font(.headline)
            Text(email.displaySubject)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(email.displayPreview)
                .font(.caption)
                .foregroundStyle(.tertiary)
                .lineLimit(2)
        }
        .padding(.vertical, 4)
    }
}
