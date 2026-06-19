# CalendarProviderSMS

An iOS app that reads your Google Calendar events, finds attendees' phone numbers from your Contacts, and opens the native Messages app to send them all a text.

## App Flow

1. Sign in with Google (Google Calendar read access only)
2. Browse upcoming events (next 30 days) that have attendees
3. Tap an event → attendees are matched to your Contacts automatically
4. Toggle which attendees to include
5. Write your message → tap **Send via Messages**
6. The native Messages app opens with all recipients and your message pre-filled

## Setup Instructions

### 1. Create a Google Cloud Project

1. Go to [console.cloud.google.com](https://console.cloud.google.com)
2. Create a new project (e.g., "CalendarProviderSMS")
3. Go to **APIs & Services → Library**
4. Search for **Google Calendar API** and enable it

### 2. Create an OAuth 2.0 Client ID

1. Go to **APIs & Services → Credentials**
2. Click **Create Credentials → OAuth client ID**
3. Choose **iOS** as the application type
4. Enter your app's Bundle ID (e.g., `com.yourname.CalendarProviderSMS`)
5. Click **Create**
6. Note your **Client ID** and **Reversed client ID**

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

In Xcode, open `Info.plist` (or your target's Info tab) and add:

| Key | Value |
|-----|-------|
| `GIDClientID` | Your OAuth Client ID (e.g., `123456789-abc.apps.googleusercontent.com`) |
| `CFBundleURLTypes` → URL Schemes | Your **Reversed** Client ID (e.g., `com.googleusercontent.apps.123456789-abc`) |
| `NSContactsUsageDescription` | Already included — explains why contacts access is needed |

### 6. Add GoogleSignIn via Swift Package Manager

1. In Xcode: **File → Add Package Dependencies**
2. Enter: `https://github.com/google/GoogleSignIn-iOS`
3. Choose version: **Up to Next Major from 7.0.0**
4. Add **GoogleSignIn** to your app target

### 7. Add MessageUI Framework

1. Select your app target in Xcode
2. Go to **General → Frameworks, Libraries, and Embedded Content**
3. Click **+** and add **MessageUI.framework**

### 8. Build and Run

> **Important:** SMS sending only works on a **real iPhone** — not the simulator.

Connect your iPhone, select it as the run destination, and build.

## Notes

- Only events with other attendees are shown (you are excluded from the list)
- Attendees without a matching phone number in your Contacts are shown grayed out and cannot be selected
- The app never sends SMS automatically — it always opens the native Messages app for your review before sending
- Google Calendar access is read-only; the app never modifies your calendar

## Permissions Used

| Permission | Why |
|------------|-----|
| Google Calendar (read-only) | To fetch your upcoming events and attendees |
| Contacts (read) | To look up phone numbers for attendee emails |
| Messages | Opens the native Messages app to send SMS |
