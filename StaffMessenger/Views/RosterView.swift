import SwiftUI
import MessageUI

struct RosterView: View {
    @EnvironmentObject var calendarService: CalendarService

    @State private var assignments: [StaffAssignment] = []
    @State private var isLoadingContacts = false
    @State private var showSettings = false
    @State private var showSMS = false

    private var tomorrowLabel: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "EEEE, MMMM d"
        return fmt.string(from: calendarService.tomorrowDate)
    }

    private var messageText: String {
        MessageComposer.compose(for: calendarService.tomorrowDate, assignments: assignments)
    }

    private var allRecipients: [String] {
        var phones = assignments.compactMap { $0.phoneNumber }
        let coord = calendarService.coordinatorPhone.trimmingCharacters(in: .whitespaces)
        if !coord.isEmpty { phones.insert(coord, at: 0) }
        return phones
    }

    private var canSend: Bool {
        MFMessageComposeViewController.canSendText() && !allRecipients.isEmpty
    }

    var body: some View {
        List {
            // Date banner
            Section {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundStyle(.blue)
                    Text(tomorrowLabel)
                        .font(.headline)
                }
            }

            // Roster
            Section("Staff") {
                if calendarService.isLoading || isLoadingContacts {
                    HStack {
                        Spacer()
                        ProgressView(calendarService.isLoading ? "Loading calendar…" : "Looking up contacts…")
                        Spacer()
                    }
                } else if let error = calendarService.errorMessage {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                        .font(.callout)
                } else if assignments.isEmpty {
                    Text("No matching events found for tomorrow.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(assignments) { assignment in
                        AssignmentRow(assignment: assignment)
                    }
                }
            }

            // Message preview
            if !assignments.isEmpty {
                Section("Message Preview") {
                    Text(messageText)
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.primary)
                }

                // Recipients summary
                Section("Recipients") {
                    let coord = calendarService.coordinatorPhone.trimmingCharacters(in: .whitespaces)
                    if !coord.isEmpty {
                        Label("Coordinator: \(coord)", systemImage: "star.fill")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                    ForEach(assignments) { a in
                        if let phone = a.phoneNumber {
                            Label("\(a.displayName): \(phone)", systemImage: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.green)
                        } else {
                            Label("\(a.displayName): not found in Contacts", systemImage: "exclamationmark.circle")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                }
            }
        }
        .navigationTitle("Tomorrow's Roster")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showSettings = true } label: { Image(systemName: "gear") }
            }
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    Task { await reload() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(calendarService.isLoading || isLoadingContacts)
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 0) {
                Divider()
                Button {
                    showSMS = true
                } label: {
                    Label(
                        "Send to \(allRecipients.count) Recipient\(allRecipients.count == 1 ? "" : "s")",
                        systemImage: "message.fill"
                    )
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(canSend ? Color.green : Color.gray)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(!canSend)
                .padding()
                .background(.regularMaterial)

                if !MFMessageComposeViewController.canSendText() {
                    Text("SMS only works on a real iPhone, not the simulator.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 8)
                }
            }
        }
        .navigationDestination(isPresented: $showSettings) {
            SetupView()
        }
        .smsComposer(isPresented: $showSMS, recipients: allRecipients, messageBody: messageText)
        .task { await reload() }
    }

    private func reload() async {
        await calendarService.fetchTomorrowsRoster()
        await loadContacts()
    }

    private func loadContacts() async {
        guard !calendarService.assignments.isEmpty else {
            assignments = []
            return
        }

        isLoadingContacts = true
        let hasAccess = await ContactsService.shared.requestAccess()

        var loaded = calendarService.assignments
        if hasAccess {
            for i in loaded.indices {
                if let result = await ContactsService.shared.lookup(rawName: loaded[i].rawName) {
                    loaded[i].displayName = result.displayName
                    loaded[i].phoneNumber = result.phone
                }
            }
        }

        assignments = loaded
        isLoadingContacts = false
    }
}

private struct AssignmentRow: View {
    let assignment: StaffAssignment

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(assignment.prefix)
                        .font(.caption.bold())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.blue.opacity(0.15))
                        .foregroundStyle(.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    Text(assignment.displayName)
                        .font(.body)
                }
                if let phone = assignment.phoneNumber {
                    Text(phone)
                        .font(.caption)
                        .foregroundStyle(.green)
                } else {
                    Text("Not found in Contacts")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            Spacer()
            Image(systemName: assignment.contactFound ? "checkmark.circle.fill" : "exclamationmark.circle")
                .foregroundStyle(assignment.contactFound ? .green : .red)
        }
    }
}
