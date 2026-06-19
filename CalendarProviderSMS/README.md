# CalendarProviderSMS

An iOS app that reads a **public** Google Calendar, matches providers to phone numbers in your Contacts, and opens the native Messages app to send them a group text — no sign-in required.

## App Flow

1. Enter a Google API key and a public Calendar ID on the setup screen
2. The app fetches upcoming events (next 30 days) that have providers listed
3. Tap an event → providers are automatically matched to your Contacts
4. Toggle which providers to include
5. Write your message → tap **Send via Messages**
6. The native Messages app opens with all recipients and your message pre-filled

## Setup Instructions

### 1. Make your Google Calendar public

1. Open [calendar.google.com](https://calendar.google.com)
2. Click the three-dot menu next to your calendar → **Settings and sharing**
3. Under **Access permissions**, check **Make available to public**
4. Copy your **Calendar ID** from the "Integrate calendar" section at the bottom

### 2. Get a Google API Key (free)

1. Go to [console.cloud.google.com](https://console.cloud.google.com)
2. Create a new project (or reuse one)
3. Go to **APIs & Services → Library** → search **Google Calendar API** → enable it
4. Go to **APIs & Services → Credentials** → **Create Credentials → API Key**
5. (Optional) Restrict the key to the Google Calendar API for security

### 3. Create an Xcode Project

1. Open Xcode → **File → New → Project**
2. Choose **iOS → App**
3. Set:
   - **Product Name**: `CalendarProviderSMS`
   - **Interface**: SwiftUI
   - **Language**: Swift
   - **Minimum Deployments**: iOS 17.0
4. Save the project

### 4. Add Source Files

Drag all files from this folder into your Xcode project:
- `CalendarProviderSMSApp.swift` (replace the generated one)
- `ContentView.swift` (replace the generated one)
- `Models/` folder
- `Services/` folder
- `Views/` folder

### 5. Configure Info.plist

Add the contents of `Resources/Info.plist` to your project's Info.plist (or replace it). The only required entry is `NSContactsUsageDescription`.

No OAuth client ID, URL schemes, or third-party SDKs are needed.

### 6. Add MessageUI Framework

1. Select your app target in Xcode
2. Go to **General → Frameworks, Libraries, and Embedded Content**
3. Click **+** and add **MessageUI.framework**

### 7. Build and Run

> **Important:** SMS sending only works on a **real iPhone** — not the simulator.

Connect your iPhone, select it as the run destination, and build.

On first launch, enter your API key and Calendar ID, then tap **Load Calendar**.

## Notes

- The app reads only events that list at least one attendee or organizer as a provider
- Providers matched to a phone number in Contacts are pre-selected; unmatched ones are shown greyed out
- The app never sends SMS automatically — it opens the native Messages app for your review
- The API key and calendar ID are stored on-device only (iOS UserDefaults)

## Permissions Used

| Permission | Why |
|------------|-----|
| Google Calendar API (read-only, API key) | To fetch upcoming events and their providers |
| Contacts (read) | To look up phone numbers for provider emails |
| Messages | Opens the native Messages app to send SMS |
