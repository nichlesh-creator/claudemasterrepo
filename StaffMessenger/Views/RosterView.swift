import SwiftUI
import MessageUI

struct RosterView: View {
    @EnvironmentObject var calendarService: CalendarService

    @State private var assignments: [StaffAssignment] = []
    @State private var isLoadingContacts = false
    @State private var showSettings = false
    @State private var showSMS = false
    @State private var showNonIphoneSMS = false
    @State private var showRenameHint = false
    @State private var showMuteHint = false

    private var nextDayLabel: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "EEEE, MMMM d"
        return fmt.string(from: calendarService.nextBusinessDay)
    }

    private var renameSuggestion: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "MM/dd"
        return "Staffing Thread for \(fmt.string(from: calendarService.nextBusinessDay))"
    }

    private var messageText: String {
        MessageComposer.compose(for: calendarService.nextBusinessDay, assignments: assignments)
    }

    private var allRecipients: [String] {
        var phones = assignments.compactMap { $0.phoneNumber }
        let coord = calendarService.coordinatorPhone.trimmingCharacters(in: .whitespaces)
        if !coord.isEmpty { phones.insert(coord, at: 0) }
        return phones
    }

    private var isInStaffingGroup: Bool {
        let myPhone = calendarService.myPhoneNumber.trimmingCharacters(in: .whitespaces)
        guard !myPhone.isEmpty else { return true }
        return allRecipients.contains(myPhone)
    }

    private var canSend: Bool {
        MFMessageComposeViewController.canSendText() && !allRecipients.isEmpty
    }

    var body: some View {
        List {
            Section {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundStyle(.blue)
                    Text(nextDayLabel)
                        .font(.headline)
                }
            }

            if !calendarService.isLoading && !isLoadingContacts
                && calendarService.errorMessage == nil
                && !calendarService.assignments.isEmpty
                && !calendarService.isStaffingDay
            {
                Section {
                    VStack(spacing: 10) {
                        Image(systemName: "moon.zzz.fill")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("No staffing scheduled")
                            .font(.headline)
                        Text("No BF1am event found for \(nextDayLabel). This may be a holiday or scheduled day off.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
            } else {
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
                        Text("No matching events found for \(nextDayLabel).")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(assignments) { assignment in
                            AssignmentRow(assignment: assignment)
                        }
                    }
                }

                if !assignments.isEmpty {
                    Section("Message Preview") {
                        Text(messageText)
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(.primary)
                    }

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

                    if showRenameHint {
                        Section {
                            VStack(alignment: .leading, spacing: 6) {
                                Label("Rename the group chat", systemImage: "pencil.circle.fill")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.orange)
                                Text("In Messages, tap the group name at the top → Edit. Paste:")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                HStack {
                                    Text(renameSuggestion)
                                        .font(.system(.callout, design: .monospaced))
                                    Spacer()
                                    Button {
                                        UIPasteboard.general.string = renameSuggestion
                                    } label: {
                                        Label("Copy", systemImage: "doc.on.doc")
                                            .font(.caption)
                                    }
                                }
                            }
                        }
                    }

                    if showMuteHint {
                        Section {
                            Label(
                                "You're not in today's staffing group. In Messages, swipe left on the thread → More → Hide Alerts to mute it.",
                                systemImage: "bell.slash.fill"
                            )
                            .font(.caption)
                            .foregroundStyle(.orange)
                        }
                    }
                }
            }
        }
        .navigationTitle("Next-Day Roster")
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
            if calendarService.isStaffingDay && !assignments.isEmpty {
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
        }
        .navigationDestination(isPresented: $showSettings) {
            SetupView()
        }
        // Primary send: staff + coordinator
        .smsComposer(isPresented: $showSMS, recipients: allRecipients, messageBody: messageText) { result in
            guard result == .sent else { return }
            showRenameHint = true
            showMuteHint = !isInStaffingGroup
            let nonIphone = calendarService.nonIphonePhones
            guard !nonIphone.isEmpty else { return }
            // Delay so the first sheet fully dismisses before the second one appears
            Task {
                try? await Task.sleep(nanoseconds: 600_000_000)
                showNonIphoneSMS = true
            }
        }
        // Secondary send: non-iPhone (Android) users
        .smsComposer(isPresented: $showNonIphoneSMS,
                     recipients: calendarService.nonIphonePhones,
                     messageBody: messageText)
        .task { await reload() }
    }

    private func reload() async {
        showRenameHint = false
        showMuteHint = false
        await calendarService.fetchNextBusinessDayRoster()
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
