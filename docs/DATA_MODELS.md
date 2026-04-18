# Data Models

This document covers all Firestore collections, Realtime Database structure, and the corresponding Dart model classes used in GaSplit.

---

## Firestore Collections

### `users/{uid}`

Stores driver profile information. Created on first login.

| Field | Type | Description |
|---|---|---|
| `uid` | `String` | Firebase Auth UID |
| `displayName` | `String` | User's display name |
| `email` | `String` | Email address |
| `photoUrl` | `String?` | Profile photo URL (Google) |
| `createdAt` | `Timestamp` | Account creation time |
| `lastTripAt` | `Timestamp?` | Timestamp of last trip |

```dart
class UserModel {
  final String uid;
  final String displayName;
  final String email;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime? lastTripAt;

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
    uid: map['uid'],
    displayName: map['displayName'],
    email: map['email'],
    photoUrl: map['photoUrl'],
    createdAt: (map['createdAt'] as Timestamp).toDate(),
    lastTripAt: map['lastTripAt'] != null
        ? (map['lastTripAt'] as Timestamp).toDate()
        : null,
  );

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'displayName': displayName,
    'email': email,
    'photoUrl': photoUrl,
    'createdAt': Timestamp.fromDate(createdAt),
    'lastTripAt': lastTripAt != null ? Timestamp.fromDate(lastTripAt!) : null,
  };
}
```

---

### `trips/{tripId}`

Stores a completed trip. Written to Firestore when the driver taps "End Trip."

| Field | Type | Description |
|---|---|---|
| `tripId` | `String` | Auto-generated Firestore ID |
| `driverId` | `String` | Firebase Auth UID of the driver |
| `startTime` | `Timestamp` | When the trip started |
| `endTime` | `Timestamp` | When the trip ended |
| `distanceKm` | `double` | Total distance tracked by GPS |
| `durationSeconds` | `int` | Trip duration in seconds |
| `fuelEfficiency` | `double` | km per liter (driver input) |
| `gasPricePerLiter` | `double` | Price in ₱ per liter (driver input) |
| `gasUsedLiters` | `double` | `distanceKm ÷ fuelEfficiency` |
| `totalCost` | `double` | `gasUsedLiters × gasPricePerLiter` |
| `passengerCount` | `int` | Total people including driver |
| `perPersonShare` | `double` | `totalCost ÷ passengerCount` |
| `startAddress` | `String` | Reverse geocoded start address |
| `endAddress` | `String` | Reverse geocoded end address |
| `polylinePoints` | `List<GeoPoint>` | GPS path of the trip |

```dart
class TripModel {
  final String tripId;
  final String driverId;
  final DateTime startTime;
  final DateTime endTime;
  final double distanceKm;
  final int durationSeconds;
  final double fuelEfficiency;
  final double gasPricePerLiter;
  final double gasUsedLiters;
  final double totalCost;
  final int passengerCount;
  final double perPersonShare;
  final String startAddress;
  final String endAddress;
  final List<GeoPoint> polylinePoints;

  factory TripModel.fromMap(String id, Map<String, dynamic> map) => TripModel(
    tripId: id,
    driverId: map['driverId'],
    startTime: (map['startTime'] as Timestamp).toDate(),
    endTime: (map['endTime'] as Timestamp).toDate(),
    distanceKm: (map['distanceKm'] as num).toDouble(),
    durationSeconds: map['durationSeconds'] as int,
    fuelEfficiency: (map['fuelEfficiency'] as num).toDouble(),
    gasPricePerLiter: (map['gasPricePerLiter'] as num).toDouble(),
    gasUsedLiters: (map['gasUsedLiters'] as num).toDouble(),
    totalCost: (map['totalCost'] as num).toDouble(),
    passengerCount: map['passengerCount'] as int,
    perPersonShare: (map['perPersonShare'] as num).toDouble(),
    startAddress: map['startAddress'] ?? '',
    endAddress: map['endAddress'] ?? '',
    polylinePoints: List<GeoPoint>.from(map['polylinePoints'] ?? []),
  );

  Map<String, dynamic> toMap() => {
    'driverId': driverId,
    'startTime': Timestamp.fromDate(startTime),
    'endTime': Timestamp.fromDate(endTime),
    'distanceKm': distanceKm,
    'durationSeconds': durationSeconds,
    'fuelEfficiency': fuelEfficiency,
    'gasPricePerLiter': gasPricePerLiter,
    'gasUsedLiters': gasUsedLiters,
    'totalCost': totalCost,
    'passengerCount': passengerCount,
    'perPersonShare': perPersonShare,
    'startAddress': startAddress,
    'endAddress': endAddress,
    'polylinePoints': polylinePoints,
  };
}
```

---

## Realtime Database Structure

Used exclusively for the **live trip meter** — data is written frequently during a trip and deleted when the trip ends.

```json
{
  "active_trips": {
    "{uid}": {
      "tripId": "abc123",
      "startTime": 1713400000000,
      "distanceKm": 6.24,
      "currentSpeedKmh": 38.5,
      "durationSeconds": 585,
      "gasUsedLiters": 0.52,
      "totalCost": 33.80,
      "passengerCount": 3,
      "perPersonShare": 11.27,
      "fuelEfficiency": 12.0,
      "gasPricePerLiter": 65.0,
      "lastUpdated": 1713400585000
    }
  }
}
```

### Rules

The Realtime DB node for a trip is:
- **Created** when the driver taps "Start Trip"
- **Updated** on every GPS location event (~every 5 meters)
- **Deleted** when the driver taps "End Trip" (after writing to Firestore)

---

## Hive Local Cache

Used for offline resilience. If the app crashes or is killed mid-trip, the active trip state is restored from Hive on next launch.

**Box name:** `active_trip`

**Key:** `current`

**Value:** JSON-serialized version of the live Realtime DB structure above.

```dart
// Writing to cache
final box = Hive.box('active_trip');
await box.put('current', activeTripJson);

// Reading from cache
final cached = box.get('current');

// Clearing after trip ends
await box.delete('current');
```

---

## Firestore Security Rules

```js
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Users can only read and write their own profile
    match /users/{uid} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
    }

    // Trips can only be read and written by the driver
    match /trips/{tripId} {
      allow read, write: if request.auth != null
        && request.auth.uid == resource.data.driverId;

      allow create: if request.auth != null
        && request.auth.uid == request.resource.data.driverId;
    }
  }
}
```

---

## Realtime Database Security Rules

```json
{
  "rules": {
    "active_trips": {
      "$uid": {
        ".read": "auth != null && auth.uid === $uid",
        ".write": "auth != null && auth.uid === $uid"
      }
    }
  }
}
```
