import SwiftUI

struct SetupView: View {
    @EnvironmentObject var calendarService: CalendarService
    @Environment(\.dismiss) private var dismiss

    @State private var apiKeyInput = ""
    @State private var calendarIDInput = ""
    @State private var coordinatorPhoneInput = ""
    @State private var prefixesInput = ""
    @State private var isSaving = false

    var body: some View {
        Form {
            Section {
                Label("No sign-in required", systemImage: "checkmark.shield.fill")
                    .foregroundStyle(.green)
                    .font(.subheadline.bold())
                Text("Reads any public Google Calendar using a free API key.")
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
                Text("console.cloud.google.com → APIs & Services → Credentials → Create API Key. Enable Google Calendar API.")
            }

            Section {
                TextField("example@group.calendar.google.com", text: $calendarIDInput)
                    .font(.system(.body, design: .monospaced))
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            } header: {
                Text("Public Calendar ID")
            } footer: {
                Text("Google Calendar → Calendar Settings → Integrate calendar → Calendar ID. Calendar must be set to Public.")
            }

            Section {
                TextField("+1 (555) 000-0000", text: $coordinatorPhoneInput)
                    .keyboardType(.phonePad)
            } header: {
                Text("Coordinator Phone Number")
            } footer: {
                Text("This person receives every daily message in addition to the listed staff.")
            }

            Section {
                TextField("E1W, E1am, OI-1, Z1am, BF1am, BE1am, EP1am", text: $prefixesInput)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            } header: {
                Text("Event Prefixes (comma-separated, in message order)")
            } footer: {
                Text("Only events whose title starts with one of these prefixes will be included. Order here = order in the message.")
            }

            Section {
                Button {
                    save()
                } label: {
                    HStack {
                        Spacer()
                        if isSaving { ProgressView() } else { Text("Save and Load Roster").font(.headline) }
                        Spacer()
                    }
                }
                .disabled(apiKeyInput.isEmpty || calendarIDInput.isEmpty || isSaving)
            }

            if let error = calendarService.errorMessage {
                Section {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                        .font(.callout)
                }
            }
        }
        .navigationTitle("Settings")
        .onAppear {
            apiKeyInput           = calendarService.apiKey
            calendarIDInput       = calendarService.calendarID
            coordinatorPhoneInput = calendarService.coordinatorPhone
            prefixesInput         = calendarService.targetPrefixes.joined(separator: ", ")
        }
    }

    private func save() {
        isSaving = true
        calendarService.apiKey           = apiKeyInput.trimmingCharacters(in: .whitespaces)
        calendarService.calendarID       = calendarIDInput.trimmingCharacters(in: .whitespaces)
        calendarService.coordinatorPhone = coordinatorPhoneInput.trimmingCharacters(in: .whitespaces)

        let prefixes = prefixesInput
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        if !prefixes.isEmpty {
            calendarService.targetPrefixes = prefixes
        }

        Task {
            await calendarService.fetchTomorrowsRoster()
            isSaving = false
            if calendarService.errorMessage == nil { dismiss() }
        }
    }
}
