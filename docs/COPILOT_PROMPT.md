# Copilot Prompt

Paste this entire prompt into GitHub Copilot Chat (or any AI coding assistant) at the start of your session. It gives the assistant the full context of GaSplit so every code suggestion follows the correct stack, architecture, and conventions.

---

## Prompt

```
You are a senior Flutter developer. Help me build GaSplit, a mobile app for 
drivers to track and split gas costs among passengers in real time. The app 
uses Flutter for the frontend and Firebase (Auth, Firestore, Realtime Database) 
as the backend.

---

APP OVERVIEW

GaSplit works like a taxi meter, but instead of fare, it calculates gas cost 
based on real-time GPS data and splits it equally among passengers. It is 
driver-only — no passenger accounts needed.

---

CORE FORMULA

  Gas Used (L)     = Distance (km) ÷ Fuel Efficiency (km/L)
  Total Gas Cost   = Gas Used × Gas Price per Liter (₱)
  Per Person Share = Total Gas Cost ÷ Number of Passengers

---

TECH STACK

  - Flutter (latest stable)
  - Firebase Auth (Google Sign-In + Email/Password)
  - Cloud Firestore (trip history, user profiles)
  - Firebase Realtime Database (live trip meter — frequent writes during trip)
  - Firebase Cloud Messaging (push notification on trip end)
  - Riverpod (state management — StateNotifier + StreamProvider)
  - go_router (navigation)
  - Packages:
      geolocator, google_maps_flutter, geocoding,
      firebase_core, firebase_auth, cloud_firestore,
      firebase_database, firebase_messaging,
      share_plus, fl_chart, hive, hive_flutter,
      flutter_foreground_task, intl, google_sign_in

---

ARCHITECTURE

Layered architecture: Presentation → Provider → Repository → Service → Data.
All colors and styles come from app_theme.dart — no hardcoded colors in widgets.
Use GasCalculator.compute() for all cost calculations.
Write to Hive and Realtime DB on every GPS update. Write to Firestore on trip end only.

---

SCREENS

1. Auth Screen (/):
   - Google Sign-In and Email/Password
   - Show last 3 trips after login
   - On auth success → navigate to /home

2. Start Journey Screen (/trip/start):
   - Google Map with animated GPS pin
   - Inputs: fuel efficiency (km/L), gas price (₱/L), passenger count (1–5+)
   - Validate all inputs before starting
   - On start → begin GPS stream, navigate to /trip/live

3. Live Trip Meter Screen (/trip/live):
   - Real-time total cost (large, updates on every GPS tick)
   - Stats: distance (km), speed (km/h), duration (mm:ss)
   - Per-passenger share list with initials avatars
   - "End Trip" button (red) with confirmation dialog
   - Wakelock enabled while screen is active

4. Trip Summary Screen (/trip/summary/:tripId):
   - Full breakdown: distance, duration, gas used, price reference
   - Per-passenger share list
   - Share button (share_plus — plain text summary)
   - Save to history (Firestore)

5. History Screen (/history):
   - Paginated Firestore list, sorted by date desc
   - Tap → navigate to /trip/summary/:tripId (read-only)

---

DATA MODELS

// Firestore: users/{uid}
{
  uid, displayName, email, photoUrl, createdAt, lastTripAt
}

// Firestore: trips/{tripId}
{
  tripId, driverId, startTime, endTime,
  distanceKm, durationSeconds,
  fuelEfficiency, gasPricePerLiter,
  gasUsedLiters, totalCost,
  passengerCount, perPersonShare,
  startAddress, endAddress,
  polylinePoints: List<GeoPoint>
}

// Realtime DB: active_trips/{uid}
{
  tripId, distanceKm, currentSpeedKmh, durationSeconds,
  gasUsedLiters, totalCost, passengerCount, perPersonShare,
  fuelEfficiency, gasPricePerLiter, lastUpdated
}

---

GPS LOGIC

- LocationAccuracy.high, distanceFilter: 5 meters
- On each position update:
    delta = distance from last position (Geolocator.distanceBetween)
    if delta > 0.5 km → discard (GPS spike)
    totalDistanceKm += delta
    recalculate cost → update Realtime DB → save to Hive
- Speed: position.speed * 3.6 (m/s → km/h)
- Duration: Stopwatch started at trip start
- On trip end: stop GPS, write to Firestore, delete Realtime DB node, clear Hive
- On app restart mid-trip: restore from Hive, resume GPS

---

UI STYLE

  Primary accent:   #F5C842 (amber)
  End action:       #E53935 (red)
  Dark surfaces:    #1A1A1A
  Card radius:      12px
  Border:           0.5px
  Font weights:     500 for values, 400 for labels
  Currency format:  ₱ symbol, 2 decimal places, fil_PH locale
  No gradients. Flat, clean, Uber-like design.
  Driver avatar: green initials circle
  Passenger avatars: blue, orange — cycling per slot

---

CONVENTIONS

- All monetary output goes through formatPeso() in currency_formatter.dart
- All distance calculations go through GasCalculator in gas_calculator.dart
- Never call Firebase directly from a screen — always through a repository
- Use const constructors wherever possible
- Handle null safety strictly — no late variables unless absolutely necessary
- Add // TODO comments where stub implementation is needed

---

When I ask you to build a specific screen, feature, function, or file, follow 
this spec exactly. Ask me which part to start with, or I will direct you.
```
