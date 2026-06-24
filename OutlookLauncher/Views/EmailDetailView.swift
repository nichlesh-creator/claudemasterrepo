import SwiftUI

struct EmailDetailView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss

    let email: GraphEmail
    let anthropicApiKey: String

    @State private var draft = ""
    @State private var isGenerating = false
    @State private var isSaving = false
    @State private var draftSaved = false
    @State private var errorMessage = ""

    private let claudeService = ClaudeService()
    private let graphService = GraphEmailService()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    emailHeader
                    draftSection
                }
                .padding()
            }
            .navigationTitle("Reply Draft")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    saveDraftButton
                }
            }
        }
    }

    private var emailHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            label("From")
            Text("\(email.fromName)  <\(email.fromAddress)>")
                .font(.subheadline)
            label("Subject").padding(.top, 2)
            Text(email.displaySubject).font(.headline)
            Divider().padding(.vertical, 4)
            Text(email.displayPreview)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    @ViewBuilder
    private var draftSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Draft Reply").font(.headline)
                Spacer()
                if isGenerating {
                    ProgressView()
                } else if !draft.isEmpty {
                    Button("Regenerate") { Task { await generate() } }
                        .font(.subheadline)
                        .disabled(anthropicApiKey.isEmpty)
                }
            }

            if draft.isEmpty && !isGenerating {
                Button("Generate with Claude") { Task { await generate() } }
                    .buttonStyle(.bordered)
                    .disabled(anthropicApiKey.isEmpty)

                if anthropicApiKey.isEmpty {
                    Text("Add an Anthropic API key in Setup to generate drafts.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else if !draft.isEmpty || isGenerating {
                TextEditor(text: $draft)
                    .font(.body)
                    .frame(minHeight: 180)
                    .padding(8)
                    .background(Color(.tertiarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .disabled(isGenerating)
            }

            if !errorMessage.isEmpty {
                Text(errorMessage).font(.caption).foregroundStyle(.red)
            }

            if draftSaved {
                Label("Draft saved to Outlook — never sent automatically.", systemImage: "checkmark.circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(.green)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    @ViewBuilder
    private var saveDraftButton: some View {
        Button {
            Task { await saveDraft() }
        } label: {
            if isSaving {
                ProgressView()
            } else {
                Text("Save Draft")
            }
        }
        .disabled(draft.isEmpty || isSaving || draftSaved)
    }

    private func label(_ text: String) -> some View {
        Text(text).font(.caption).foregroundStyle(.secondary)
    }

    private func generate() async {
        guard !anthropicApiKey.isEmpty else { return }
        isGenerating = true
        errorMessage = ""
        do {
            draft = try await claudeService.generateDraft(for: email, apiKey: anthropicApiKey)
        } catch {
            errorMessage = error.localizedDescription
        }
        isGenerating = false
    }

    private func saveDraft() async {
        guard let token = authService.accessToken, !draft.isEmpty else { return }
        isSaving = true
        errorMessage = ""
        do {
            try await graphService.createDraft(body: draft, replyingTo: email, accessToken: token)
            draftSaved = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }
}
