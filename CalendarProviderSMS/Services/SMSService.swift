import MessageUI
import SwiftUI

struct SMSComposerView: UIViewControllerRepresentable {
    let recipients: [String]
    let messageBody: String
    @Binding var isPresented: Bool

    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let vc = MFMessageComposeViewController()
        vc.recipients = recipients
        vc.body = messageBody
        vc.messageComposeDelegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: MFMessageComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(isPresented: $isPresented)
    }

    class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        @Binding var isPresented: Bool

        init(isPresented: Binding<Bool>) {
            _isPresented = isPresented
        }

        func messageComposeViewController(
            _ controller: MFMessageComposeViewController,
            didFinishWith result: MessageComposeResult
        ) {
            isPresented = false
        }
    }
}

extension View {
    func smsComposer(
        isPresented: Binding<Bool>,
        recipients: [String],
        messageBody: String
    ) -> some View {
        self.sheet(isPresented: isPresented) {
            SMSComposerView(recipients: recipients, messageBody: messageBody, isPresented: isPresented)
                .ignoresSafeArea()
        }
    }
}
