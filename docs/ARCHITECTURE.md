# Architecture

GaSplit follows a layered architecture based on the **Repository Pattern** with **Riverpod** for state management. Each layer has a single responsibility, making the codebase easy to extend and test.

---

## Layers

```
┌────────────────────────────────────┐
│         Presentation Layer         │  Screens, Widgets
├────────────────────────────────────┤
│          Provider Layer            │  Riverpod StateNotifiers
├────────────────────────────────────┤
│         Repository Layer           │  Abstract data contracts
├────────────────────────────────────┤
│          Service Layer             │  Firebase, GPS, Geocoding
├────────────────────────────────────┤
│           Data Layer               │  Models, DTOs, Hive cache
└────────────────────────────────────┘
```

---

## Folder Structure

```
lib/
├── main.dart                        # App entry point, Firebase init
├── app.dart                         # MaterialApp, routing, theme
│
├── core/
│   ├── constants/
│   │   ├── app_colors.dart          # Color palette
│   │   ├── app_strings.dart         # All user-facing strings
│   │   └── firestore_keys.dart      # Firestore collection/field names
│   ├── theme/
│   │   └── app_theme.dart           # ThemeData, text styles
│   └── utils/
│       ├── currency_formatter.dart  # ₱ formatting helpers
│       ├── distance_utils.dart      # Haversine formula
│       └── validators.dart          # Form input validation
│
├── data/
│   ├── models/
│   │   ├── trip_model.dart
│   │   └── user_model.dart
│   ├── repositories/
│   │   ├── auth_repository.dart
│   │   └── trip_repository.dart
│   └── services/
│       ├── auth_service.dart        # Firebase Auth wrapper
│       ├── firestore_service.dart   # Firestore CRUD
│       ├── realtime_db_service.dart # Live trip meter sync
│       ├── gps_service.dart         # Geolocator stream
│       ├── geocoding_service.dart   # Address resolution
│       └── fcm_service.dart         # Push notifications
│
├── presentation/
│   ├── screens/
│   │   ├── auth/
│   │   │   └── auth_screen.dart
│   │   ├── home/
│   │   │   └── home_screen.dart
│   │   ├── trip/
│   │   │   ├── start_trip_screen.dart
│   │   │   ├── live_meter_screen.dart
│   │   │   └── trip_summary_screen.dart
│   │   └── history/
│   │       └── history_screen.dart
│   └── widgets/
│       ├── map_view.dart
│       ├── live_meter_card.dart
│       ├── passenger_split_card.dart
│       ├── trip_history_tile.dart
│       └── passenger_avatar.dart
│
└── providers/
    ├── auth_provider.dart
    ├── trip_provider.dart           # Active trip state
    └── history_provider.dart
```

---

## State Management — Riverpod

GaSplit uses **Riverpod** with `StateNotifier` for mutable state and `StreamProvider` for reactive Firebase streams.

### Key Providers

```dart
// Active trip state — drives the live meter screen
final tripProvider = StateNotifierProvider<TripNotifier, TripState>(...);

// Auth state — drives routing
final authProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// Trip history — reactive Firestore stream
final historyProvider = StreamProvider.family<List<TripModel>, String>((ref, uid) {
  return ref.read(tripRepositoryProvider).watchTrips(uid);
});
```

---

## Data Flow — Live Trip

```
GPS stream (geolocator)
        │
        ▼
  GpsService.positionStream
        │
        ▼
  TripNotifier.onLocationUpdate()
   ├── accumulates distanceKm
   ├── updates currentSpeedKmh
   ├── recalculates totalCost
   ├── recalculates perPersonShare
   └── writes to Realtime DB (live sync)
        │
        ▼
  LiveMeterScreen (StreamBuilder)
   └── rebuilds UI with new values
```

---

## Data Flow — Trip End

```
Driver taps "End Trip"
        │
        ▼
  TripNotifier.endTrip()
   ├── stops GPS stream
   ├── captures endTime, endAddress (geocoding)
   ├── writes full TripModel → Firestore
   ├── clears Realtime DB live record
   ├── clears Hive local cache
   └── sends FCM push notification
        │
        ▼
  Navigate to TripSummaryScreen
```

---

## Offline Resilience

Active trip data is written to **Hive** on every GPS update. On app restart mid-trip, the `TripNotifier` checks Hive for an in-progress trip and resumes automatically.

```dart
// On app start
final cached = Hive.box('active_trip').get('current');
if (cached != null) {
  // Resume trip from last known state
}
```

---

## Navigation / Routing

GaSplit uses `go_router` for declarative routing.

| Route | Screen |
|---|---|
| `/` | AuthScreen (redirects if logged in) |
| `/home` | HomeScreen (history + start button) |
| `/trip/start` | StartTripScreen |
| `/trip/live` | LiveMeterScreen |
| `/trip/summary/:id` | TripSummaryScreen |
| `/history` | HistoryScreen |

---

## Theme

All colors, text styles, and spacing values are defined in `core/theme/app_theme.dart` and accessed via `Theme.of(context)`. No hardcoded colors in widgets.

```dart
// Example
const Color primaryAccent = Color(0xFFF5C842);   // Amber
const Color dangerColor   = Color(0xFFE53935);   // Red (end trip)
const Color darkSurface   = Color(0xFF1A1A1A);   // Dark hero areas
```
