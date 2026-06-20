import SwiftUI
import MessageUI

struct ComposeMessageView: View {
    let providers: [Provider]

    @State private var messageText = ""
    @State private var showSMSComposer = false
    @State private var smsSentResult: MessageComposeResult?

    private let canSendSMS = MFMessageComposeViewController.canSendText()

    private var phoneNumbers: [String] {
        providers.compactMap { $0.phoneNumber }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Recipients
            VStack(alignment: .leading, spacing: 8) {
                Text("To:")
                    .font(.subheadline.bold())
                    .padding(.horizontal)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(providers) { provider in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(provider.name)
                                    .font(.caption.bold())
                                if let phone = provider.phoneNumber {
                                    Text(phone)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(.blue.opacity(0.1))
                            .foregroundStyle(.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical, 12)

            Divider()

            // Message body
            TextEditor(text: $messageText)
                .padding(.horizontal, 12)
                .overlay(alignment: .topLeading) {
                    if messageText.isEmpty {
                        Text("Type your message here...")
                            .foregroundStyle(.tertiary)
                            .padding(.top, 8)
                            .padding(.leading, 16)
                            .allowsHitTesting(false)
                    }
                }
                .frame(maxHeight: .infinity)

            Divider()

            // Send button
            VStack(spacing: 8) {
                if !canSendSMS {
                    Label("SMS is not available on this device (or simulator).", systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .multilineTextAlignment(.center)
                }

                if let result = smsSentResult {
                    Text(resultMessage(result))
                        .font(.caption)
                        .foregroundStyle(result == .sent ? .green : .secondary)
                }

                Button {
                    showSMSComposer = true
                } label: {
                    Label("Send via Messages", systemImage: "message.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canSend ? Color.green : Color.gray)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(!canSend)
            }
            .padding()
        }
        .navigationTitle("Compose Message")
        .navigationBarTitleDisplayMode(.inline)
        .smsComposer(
            isPresented: $showSMSComposer,
            recipients: phoneNumbers,
            messageBody: messageText
        )
    }

    private var canSend: Bool {
        canSendSMS && !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func resultMessage(_ result: MessageComposeResult) -> String {
        switch result {
        case .sent: return "Message sent successfully."
        case .cancelled: return "Message cancelled."
        case .failed: return "Message failed to send."
        @unknown default: return ""
        }
    }
}
