# ASHESI LIFE

A comprehensive mobile application designed to enhance the student experience at Ashesi University. ASHESI LIFE provides students with seamless access to campus announcements, events, clubs, directory information, and a platform to report issues.

## Features

- **Announcements**: Stay updated with the latest campus announcements and news
- **Events**: Browse and discover upcoming campus events
- **Clubs & Organizations**: Explore and connect with student clubs and organizations
- **Directory**: Search for students and staff members across campus
- **Issue Reporting**: Report campus issues and concerns directly through the app
- **User Authentication**: Secure login and signup with Firebase Authentication
- **Real-time Data**: Sync with Firebase Firestore for live updates

## Project Structure

```
lib/
├── models/              # Data models (Announcement, Club, Event, etc.)
├── screens/             # UI screens (Home, Clubs, Directory, etc.)
├── services/            # Business logic and Firebase integration
├── theme/               # App theming and styling
├── widgets/             # Reusable UI components
├── auth_service.dart    # Authentication logic
├── firebase_options.dart # Firebase configuration
└── main.dart            # App entry point
```

## Getting Started

### Prerequisites
- Flutter SDK (latest version)
- Dart SDK
- Firebase account and project setup
- Android Studio or Xcode for mobile development

### Installation

1. Clone the repository:
```bash
git clone https://github.com/billionzz798/ASHESI-LIFE.git
cd ASHESI-LIFE
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

## Building

### Build for Android:
```bash
flutter build apk
```

### Build for iOS:
```bash
flutter build ios
```

## Firebase Setup

Ensure your Firebase project is configured with:
- Firebase Authentication (Email/Password)
- Cloud Firestore database
- Proper security rules for data access

The Firebase configuration is located in `lib/firebase_options.dart`.

## Technologies Used

- **Flutter**: Cross-platform mobile framework
- **Firebase**: Backend services (Auth, Firestore, Cloud Messaging)
- **Dart**: Programming language
- **Provider/State Management**: For app state management

## Contributing

Contributions are welcome! Please create a feature branch and submit a pull request with your changes.

## License

This project is part of Ashesi University's educational platform.
