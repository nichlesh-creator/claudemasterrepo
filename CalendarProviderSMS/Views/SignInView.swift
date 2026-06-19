import SwiftUI

struct SignInView: View {
    @EnvironmentObject var calendarService: GoogleCalendarService

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "calendar.badge.plus")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundStyle(.blue)

            Text("Calendar Provider SMS")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)

            Text("Sign in with Google to view upcoming events and send SMS to attendees.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()

            Button {
                Task { await calendarService.signIn() }
            } label: {
                HStack {
                    Image(systemName: "person.circle.fill")
                    Text("Sign in with Google")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(.blue)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 32)

            if let error = calendarService.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()
        }
        .navigationTitle("")
        .navigationBarHidden(true)
    }
}
