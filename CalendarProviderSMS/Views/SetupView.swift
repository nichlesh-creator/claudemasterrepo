import SwiftUI

struct SetupView: View {
    @EnvironmentObject var calendarService: CalendarService
    @Environment(\.dismiss) private var dismiss

    @State private var apiKeyInput = ""
    @State private var calendarIDInput = ""
    @State private var isSaving = false

    private var canSave: Bool {
        !apiKeyInput.trimmingCharacters(in: .whitespaces).isEmpty &&
        !calendarIDInput.trimmingCharacters(in: .whitespaces).isEmpty &&
        !isSaving
    }

    var body: some View {
        Form {
            Section {
                Label("No sign-in required", systemImage: "checkmark.shield.fill")
                    .foregroundStyle(.green)
                    .font(.subheadline.bold())
                Text("Reads any public Google Calendar using a free API key — your data stays on your device.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section {
                TextField("AIzaSy…", text: $apiKeyInput)
                    .font(.system(.body, design: .monospaced))
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            } header: {
                Text("Google API Key")
            } footer: {
                Text("Create a free key at console.cloud.google.com → APIs & Services → Credentials → Create API Key. Enable the Google Calendar API on the same project.")
            }

            Section {
                TextField("example@group.calendar.google.com", text: $calendarIDInput)
                    .font(.system(.body, design: .monospaced))
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            } header: {
                Text("Public Calendar ID")
            } footer: {
                Text("In Google Calendar: open the calendar's settings → scroll to \"Integrate calendar\" → copy the Calendar ID. The calendar must be set to Public.")
            }

            Section {
                Button {
                    save()
                } label: {
                    HStack {
                        Spacer()
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("Load Calendar")
                                .font(.headline)
                        }
                        Spacer()
                    }
                }
                .disabled(!canSave)
            }

            if let error = calendarService.errorMessage {
                Section {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                        .font(.callout)
                }
            }
        }
        .navigationTitle("Calendar Setup")
        .onAppear {
            apiKeyInput = calendarService.apiKey
            calendarIDInput = calendarService.calendarID
        }
    }

    private func save() {
        isSaving = true
        calendarService.apiKey = apiKeyInput.trimmingCharacters(in: .whitespaces)
        calendarService.calendarID = calendarIDInput.trimmingCharacters(in: .whitespaces)
        Task {
            await calendarService.fetchEvents()
            isSaving = false
            if calendarService.errorMessage == nil {
                dismiss()
            }
        }
    }
}
