# GPS Tracking

This document covers how GaSplit uses GPS to accumulate distance, compute speed, and drive the live gas meter.

---

## Package

GaSplit uses the [`geolocator`](https://pub.dev/packages/geolocator) package for location access.

```yaml
dependencies:
  geolocator: ^10.x.x
```

---

## Location Settings

```dart
const LocationSettings locationSettings = LocationSettings(
  accuracy: LocationAccuracy.high,
  distanceFilter: 5, // Only emit updates when moved ≥ 5 meters
);
```

Using `distanceFilter: 5` prevents the meter from ticking up due to GPS drift while stationary.

---

## GPS Service

```dart
class GpsService {
  StreamSubscription<Position>? _subscription;
  Position? _lastPosition;

  Stream<Position> get positionStream =>
      Geolocator.getPositionStream(locationSettings: locationSettings);

  Future<Position> getCurrentPosition() async {
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  /// Distance in km between two GPS positions using Geolocator's built-in method
  double distanceBetween(Position from, Position to) {
    final meters = Geolocator.distanceBetween(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    );
    return meters / 1000.0; // convert to km
  }

  void dispose() {
    _subscription?.cancel();
  }
}
```

---

## Distance Accumulation

On each position update, the delta distance from the previous position is added to a running total.

```dart
void onLocationUpdate(Position newPosition) {
  if (_lastPosition == null) {
    _lastPosition = newPosition;
    return;
  }

  final deltaKm = _gpsService.distanceBetween(_lastPosition!, newPosition);

  // Sanity cap: ignore GPS jumps > 500m in a single update
  if (deltaKm > 0.5) {
    _lastPosition = newPosition;
    return;
  }

  _totalDistanceKm += deltaKm;
  _lastPosition = newPosition;

  _recalculate(); // update cost and share
  _syncToRealtimeDb();
  _saveToHive();
}
```

---

## Speed Display

Speed is read directly from the `Position` object. `geolocator` provides it in meters per second — convert to km/h for display.

```dart
double speedKmh(Position position) {
  // position.speed is in m/s
  final kmh = position.speed * 3.6;
  return kmh < 0 ? 0 : kmh; // negative = invalid, show 0
}
```

---

## Trip Duration

A `Stopwatch` is used for trip duration, started when the GPS stream begins.

```dart
final _stopwatch = Stopwatch();

void startTrip() {
  _stopwatch.start();
  // ... start GPS stream
}

void endTrip() {
  _stopwatch.stop();
  final durationSeconds = _stopwatch.elapsedMilliseconds ~/ 1000;
}

// Live display — formatted as mm:ss
String get formattedDuration {
  final s = _stopwatch.elapsed.inSeconds;
  final minutes = (s ~/ 60).toString().padLeft(2, '0');
  final seconds = (s % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
```

---

## Background Tracking

To continue tracking when the app is minimized, enable background location:

### Android

In `AndroidManifest.xml` add:

```xml
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION"/>

<service
  android:name="com.baseflow.geolocator.GeolocatorService"
  android:enabled="true"
  android:exported="false"
  android:foregroundServiceType="location"/>
```

### iOS

In `Info.plist`:

```xml
<key>UIBackgroundModes</key>
<array>
  <string>location</string>
</array>
```

### Flutter

Use the `flutter_foreground_task` package to keep the GPS service alive:

```dart
FlutterForegroundTask.startService(
  notificationTitle: 'GaSplit is tracking your trip',
  notificationText: 'Tap to return to the app',
  callback: startCallback,
);
```

---

## Realtime Database Sync

During an active trip, the current state is written to Firebase Realtime DB on every GPS tick so the data persists even if the app is closed unexpectedly.

```dart
Future<void> _syncToRealtimeDb() async {
  final ref = FirebaseDatabase.instance.ref('active_trips/$_uid');
  await ref.set({
    'tripId': _tripId,
    'distanceKm': _totalDistanceKm,
    'currentSpeedKmh': _currentSpeedKmh,
    'durationSeconds': _stopwatch.elapsed.inSeconds,
    'gasUsedLiters': _gasUsedLiters,
    'totalCost': _totalCost,
    'passengerCount': _passengerCount,
    'perPersonShare': _perPersonShare,
    'lastUpdated': ServerValue.timestamp,
  });
}
```

---

## Hive Offline Cache

In addition to Realtime DB, the same state is written to Hive locally on each update. This handles cases where the device is offline.

```dart
Future<void> _saveToHive() async {
  final box = Hive.box('active_trip');
  await box.put('current', {
    'tripId': _tripId,
    'distanceKm': _totalDistanceKm,
    'totalCost': _totalCost,
    'perPersonShare': _perPersonShare,
    'passengerCount': _passengerCount,
    'fuelEfficiency': _fuelEfficiency,
    'gasPricePerLiter': _gasPricePerLiter,
    'startTime': _startTime.toIso8601String(),
    'durationSeconds': _stopwatch.elapsed.inSeconds,
  });
}
```

---

## Trip Restore on App Launch

On app startup, if a Hive cache is found for an unfinished trip, the `TripNotifier` restores the state and resumes GPS tracking automatically.

```dart
Future<void> checkForInProgressTrip() async {
  final box = Hive.box('active_trip');
  final cached = box.get('current');

  if (cached != null) {
    // Restore state
    _totalDistanceKm = cached['distanceKm'];
    _totalCost = cached['totalCost'];
    // ... restore all fields

    // Resume GPS stream
    _startGpsStream();

    // Navigate to live meter screen
    _router.go('/trip/live');
  }
}
```

---

## Permissions Request Flow

```dart
Future<bool> requestLocationPermission() async {
  LocationPermission permission = await Geolocator.checkPermission();

  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }

  if (permission == LocationPermission.deniedForever) {
    // Direct user to app settings
    await Geolocator.openAppSettings();
    return false;
  }

  return permission == LocationPermission.whileInUse ||
         permission == LocationPermission.always;
}
```
