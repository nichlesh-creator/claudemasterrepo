import MessageUI
import SwiftUI

struct SMSComposerView: UIViewControllerRepresentable {
    let recipients: [String]
    let messageBody: String
    @Binding var isPresented: Bool
    var onComplete: ((MessageComposeResult) -> Void)?

    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let vc = MFMessageComposeViewController()
        vc.recipients = recipients
        vc.body = messageBody
        vc.messageComposeDelegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: MFMessageComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(isPresented: $isPresented, onComplete: onComplete)
    }

    class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        @Binding var isPresented: Bool
        let onComplete: ((MessageComposeResult) -> Void)?

        init(isPresented: Binding<Bool>, onComplete: ((MessageComposeResult) -> Void)?) {
            _isPresented = isPresented
            self.onComplete = onComplete
        }

        func messageComposeViewController(_ controller: MFMessageComposeViewController,
                                          didFinishWith result: MessageComposeResult) {
            isPresented = false
            onComplete?(result)
        }
    }
}

extension View {
    func smsComposer(
        isPresented: Binding<Bool>,
        recipients: [String],
        messageBody: String,
        onComplete: ((MessageComposeResult) -> Void)? = nil
    ) -> some View {
        self.sheet(isPresented: isPresented) {
            SMSComposerView(
                recipients: recipients,
                messageBody: messageBody,
                isPresented: isPresented,
                onComplete: onComplete
            )
            .ignoresSafeArea()
        }
    }
}
