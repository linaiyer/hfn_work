# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Flutter mobile application called "HFN For Work" - a time tracking and productivity app with Firebase backend integration. The app includes user authentication, time tracking functionality, video content playback, and local notifications.

## Development Commands

### Flutter Commands
- `flutter run` - Run the app on connected device/emulator
- `flutter run --release` - Run app in release mode
- `flutter build apk` - Build Android APK
- `flutter build ios` - Build iOS app
- `flutter clean` - Clean build artifacts
- `flutter pub get` - Get dependencies
- `flutter pub upgrade` - Upgrade dependencies
- `flutter analyze` - Run static analysis
- `flutter test` - Run tests

### Testing
- Test files are located in the `test/` directory
- Run individual tests: `flutter test test/specific_test.dart`

## Architecture & Structure

### Core Architecture
- **Framework**: Flutter with Dart
- **State Management**: Provider pattern with MultiProvider
- **Backend**: Firebase (Firestore, Auth, Storage, Messaging)
- **Navigation**: MaterialApp with global navigator key
- **Notifications**: Local notifications with timezone support
- **Connectivity**: Real-time connectivity monitoring

### Key Components

#### Authentication Flow
- `lib/auth_screen/` - Contains all authentication related screens
  - `splash_screen.dart` - App initialization and routing
  - `login.dart` - User login with Firebase Auth
  - `create_account.dart` - User registration
  - `create_account_sso.dart` - SSO registration (Google, Apple)
  - `welcome.dart` - Welcome/onboarding screen

#### Main Application Logic
- `lib/main.dart` - App entry point with time tracking logic embedded in MyApp widget
  - Contains global stopwatch functionality for time tracking
  - Firebase initialization
  - Timezone and notification setup
  - HTTP overrides for certificate handling

#### Time Tracking System
- Integrated directly into main.dart MyApp state
- Uses Firestore collection 'watchDataTable' for data persistence
- Tracks time by week/day format (W1 D1, W2 D3, etc.)
- Calculates elapsed time and stores formatted strings

#### User Interface
- `lib/main_screen/` - Main application screens
  - `user_screen/` - User-specific functionality including video playback
  - `settings_screen.dart` - App settings
  - `download_data.dart` - Data export functionality
  - `terms_of_use.dart` - Legal content
- `lib/bottom_shet/` - Bottom navigation components

#### Utilities & Common Components
- `lib/utils/` - Shared utilities and widgets
  - `common_widgets.dart` - Reusable UI components
  - `styles.dart` - App theming and styling
  - `LoadCsvDataScreen.dart` - CSV data handling
  - `circle_loader.dart` - Loading indicators
  - `toast_show.dart` - Toast notifications

#### Notifications
- `lib/notification/` - Push and local notification handling
  - Uses flutter_local_notifications_plus
  - Firebase messaging integration
  - Timezone-aware scheduling

### Firebase Integration
- **Authentication**: Email/password, Google Sign-In, Sign in with Apple
- **Firestore Collections**:
  - `user` - User profiles and settings
  - `watchDataTable` - Time tracking data
- **Storage**: File uploads and media storage
- **Messaging**: Push notifications

### Key Dependencies
- **Firebase**: Core, Auth, Firestore, Storage, Messaging
- **UI**: Material Design, Cupertino, Charts (fl_chart)
- **Media**: Video player (chewie), Audio (just_audio), Image picker
- **Utilities**: Provider (state management), shared_preferences, connectivity monitoring
- **Notifications**: flutter_local_notifications_plus with timezone support

## Platform-Specific Notes

### Android
- Uses Kotlin for native code (`MainActivity.kt`)
- Google Services integration via `google-services.json`
- Build configuration in `android/app/build.gradle.kts`
- Minimum SDK version defined in Flutter configuration

### iOS
- Swift-based implementation
- Podfile manages iOS dependencies
- Asset catalogs for app icons and launch images
- Code signing configuration for release builds

## Development Workflow

### Adding New Features
1. Follow the existing directory structure under `lib/`
2. Use Provider for state management
3. Integrate with existing Firebase collections when needed
4. Follow the app's color scheme (primary: #C299F6)
5. Maintain portrait-only orientation

### Firebase Integration
- User da
- 
- ta queries use compound where clauses (id + user_type)
- Time tracking data uses specific naming conventions for periods
- All Firebase operations should include proper error handling

### Styling & Theming
- Primary color: #C299F6 with material color swatch generation
- Custom fonts: GoudyBookletterRegular, Anaheim, Avenir, WorkSans
- Assets organized in `assets/` with subdirectories for images, icons, audio, fonts

## Important Implementation Details

### Time Tracking Logic
The app's core time tracking functionality is embedded directly in the main MyApp widget state. When implementing time tracking features:
- Data is stored in Firestore with week/day format keys
- Time calculations use Duration parsing and formatting
- Updates are real-time but require proper state management

### Notification System
- Local notifications are timezone-aware using flutter_native_timezone
- Push notifications integrate with Firebase Messaging
- Notification payload handling requires proper routing setup

### Connectivity Monitoring
- App includes real-time connectivity status monitoring
- Shows custom toast notifications when offline
- Provider pattern used for connectivity state management