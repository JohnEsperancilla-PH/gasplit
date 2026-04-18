# Setup Guide

This document covers everything needed to get GaSplit running locally from scratch.

---

## Prerequisites

- Flutter SDK `>=3.0.0`
- Dart SDK `>=3.0.0`
- Android Studio or Xcode (for emulator/simulator)
- A Firebase project
- A Google Cloud project with Maps SDK enabled

---

## 1. Clone the Repository

```bash
git clone https://github.com/your-username/gasplit.git
cd gasplit
```

---

## 2. Install Dependencies

```bash
flutter pub get
```

### Required packages (`pubspec.yaml`)

```yaml
dependencies:
  flutter:
    sdk: flutter

  # Firebase
  firebase_core: ^2.x.x
  firebase_auth: ^4.x.x
  cloud_firestore: ^4.x.x
  firebase_database: ^10.x.x
  firebase_messaging: ^14.x.x

  # Maps & GPS
  google_maps_flutter: ^2.x.x
  geolocator: ^10.x.x
  geocoding: ^2.x.x

  # Local storage
  hive: ^2.x.x
  hive_flutter: ^1.x.x

  # UI & utilities
  share_plus: ^7.x.x
  fl_chart: ^0.x.x
  intl: ^0.18.x
  google_sign_in: ^6.x.x
```

---

## 3. Firebase Setup

### 3.1 Create a Firebase Project

1. Go to [console.firebase.google.com](https://console.firebase.google.com)
2. Click **Add project** → name it `GaSplit`
3. Disable Google Analytics (optional) → **Create project**

### 3.2 Add Android App

1. Click **Add app** → Android
2. Enter package name: `com.yourname.gasplit`
3. Download `google-services.json`
4. Place it in `android/app/`

### 3.3 Add iOS App

1. Click **Add app** → iOS
2. Enter bundle ID: `com.yourname.gasplit`
3. Download `GoogleService-Info.plist`
4. Place it in `ios/Runner/` via Xcode

### 3.4 Enable Firebase Services

In the Firebase console, enable the following:

| Service | Notes |
|---|---|
| Authentication | Enable Google and Email/Password providers |
| Cloud Firestore | Start in **test mode** for development |
| Realtime Database | Start in **test mode** for development |
| Cloud Messaging | No extra config needed |

### 3.5 Install FlutterFire CLI

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

This generates `lib/firebase_options.dart` automatically.

---

## 4. Google Maps Setup

### 4.1 Enable APIs

In [Google Cloud Console](https://console.cloud.google.com), enable:

- Maps SDK for Android
- Maps SDK for iOS
- Geocoding API

### 4.2 Add API Key — Android

In `android/app/src/main/AndroidManifest.xml`, inside `<application>`:

```xml
<meta-data
  android:name="com.google.android.geo.API_KEY"
  android:value="YOUR_GOOGLE_MAPS_API_KEY"/>
```

### 4.3 Add API Key — iOS

In `ios/Runner/AppDelegate.swift`:

```swift
import GoogleMaps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("YOUR_GOOGLE_MAPS_API_KEY")
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

---

## 5. Permissions

### Android (`android/app/src/main/AndroidManifest.xml`)

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION"/>
<uses-permission android:name="android.permission.INTERNET"/>
```

### iOS (`ios/Runner/Info.plist`)

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>GaSplit needs location access to track your trip distance.</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>GaSplit needs background location to continue tracking when the app is minimized.</string>
```

---

## 6. Environment Variables

Create a `.env` file at the root (do not commit this):

```env
GOOGLE_MAPS_API_KEY=your_key_here
```

Use `flutter_dotenv` to load it, or manage keys via your CI/CD pipeline.

---

## 7. Run the App

```bash
# Run on connected device or emulator
flutter run

# Run on specific platform
flutter run -d android
flutter run -d ios
```

---

## 8. Build for Release

```bash
# Android APK
flutter build apk --release

# Android App Bundle (for Play Store)
flutter build appbundle --release

# iOS (requires macOS + Xcode)
flutter build ios --release
```

---

## Troubleshooting

**`google-services.json` not found**
Make sure it's placed in `android/app/`, not the project root.

**Maps not rendering**
Double-check your API key is enabled for the correct SDK in Google Cloud Console.

**Location not updating**
On Android emulator, set a mock location in the extended controls panel.
