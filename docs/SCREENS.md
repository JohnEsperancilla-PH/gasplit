# Screens

A screen-by-screen breakdown of GaSplit's UI, features, and navigation behavior.

---

## 1. Auth Screen

**Route:** `/`

**Status:** Implemented (UI + navigation stub)

The entry point of the app. Shows the brand hero and login options. If the user is already authenticated, they are redirected to `/home` immediately.

### UI Elements

- App logo (⛽ icon on amber background)
- App name: **GaSplit**
- Tagline: *"Split the ride, not the friendship"*
- Google Sign-In button
- Email / Password sign-in button
- Recent trips list (last 3 trips, shown after first login)

### Recent Trip Tile

Each tile shows:
- Colored status dot (green = completed)
- Route label (e.g. `Roxas Ave → SM City`)
- Metadata: date, passenger count, distance
- User's share amount (e.g. `₱24.50`)

### Behavior

- On successful login → navigate to `/home`
- On first login → navigate to `/home` with empty history
- Failed auth → show snackbar error

---

## 2. Home Screen

**Route:** `/home`

**Status:** Implemented (UI + navigation)

The main hub after login. Shows a summary of past trips and the primary call-to-action to start a new trip.

### UI Elements

- Top bar: user avatar, greeting, logout icon
- "Start a new trip" button (full-width, amber)
- Trip history list (see History Screen for tile details)
- Empty state illustration if no trips yet

---

## 3. Start Journey Screen

**Route:** `/trip/start`

**Status:** Implemented (form + validation + navigation)

Where the driver configures the trip before departure.

### UI Elements

- Live Google Map with animated GPS pin pulse (similar to Uber's waiting state)
- Section: **Vehicle details**
  - Fuel efficiency input (km/L) — numeric keyboard, default `12`
  - Gas price per liter (₱) — numeric keyboard, pre-filled with last used value
- Section: **Number of passengers**
  - Segmented selector: `1`, `2`, `3`, `4`, `5+`
  - For `5+`, show a text input for exact count
- "Start Trip" button (dark, full-width)

### Validation

- Fuel efficiency must be > 0
- Gas price must be > 0
- Passenger count must be selected

### Behavior

- On "Start Trip" → initialize `TripNotifier`, start GPS stream, navigate to `/trip/live`
- Map centers on current GPS location automatically

---

## 4. Live Trip Meter Screen

**Route:** `/trip/live`

**Status:** Implemented (UI + simulated live meter updates)

The core screen of the app. Displays the live gas meter and per-person split.

### UI Elements

**Map area (top)**
- Google Map showing route polyline as the car moves
- Start point marker, current position marker

**Live badge**
- Pulsing amber dot + "Live" label

**Total cost**
- Large number (e.g. `₱73.80`), updates in real time
- Label: `Total gas cost · tap to view formula`
- Tapping shows a bottom sheet with the formula breakdown

**Stats row (3 cards)**
- Distance (km)
- Current speed (km/h)
- Duration (live timer)

**Per-person split card**
- Header: `Per-person share` + `N passengers`
- Rows for each passenger slot:
  - Initials avatar (colored circle)
  - Name (driver labeled as "you", others as Passenger 2/3...)
  - Share amount (updates live)

**End Trip button**
- Red, full-width, at the bottom
- Confirmation dialog before ending

### Behavior

- Screen stays active (wakelock enabled) during trip
- If app is backgrounded, GPS continues via background service
- On "End Trip" confirmed → stop GPS, save trip, navigate to `/trip/summary/:id`

---

## 5. Trip Summary Screen

**Route:** `/trip/summary/:tripId`

**Status:** Implemented (UI + local share preview/copy + save stub)

Shown immediately after a trip ends, and also accessible from history.

### UI Elements

**Hero (dark background)**
- Green checkmark circle
- Total cost (large)
- Date/time of trip

**Details section**
- Distance
- Duration
- Gas used (L)
- Fuel efficiency + gas price reference

**Per-passenger breakdown**
- List of passenger tiles (avatar, name, share amount)
- Driver tile uses green accent

**Action buttons**
- "Share Breakdown" (amber, full-width) — generates plain-text summary with copy-ready preview
- "Save to History" (outlined) — local stub action while Firestore integration is pending

### Share Text Format

```
⛽ GaSplit Trip Summary
📅 Apr 18, 2026
📍 Roxas Ave → SM City
📏 6.2 km · 12 min

Total gas cost: ₱73.80
Per person (3 pax): ₱24.60

Powered by GaSplit
```

---

## 6. History Screen

**Route:** `/history`

**Status:** Implemented (search, list, refresh, and summary navigation)

A full list of all completed trips for the logged-in driver.

### UI Elements

- Search bar (filter by date or route)
- Trip list sorted by date descending
- Each tile shows:
  - Route (start → end address)
  - Date and time
  - Passenger count
  - Total cost + per-person share
  - Distance and duration

### Behavior

- Tap any tile → navigate to `/trip/summary/:tripId` (read-only view)
- Pull to refresh
- Infinite scroll / pagination (Firestore query cursor)

---

## Formula Bottom Sheet

**Status:** Implemented (available from live meter total cost label)

Accessible by tapping the total cost on the Live Meter screen.

Shows the live calculation broken down:

```
Distance:         6.2 km
Fuel efficiency:  12 km/L
Gas used:         6.2 ÷ 12 = 0.517 L
Gas price:        ₱65.00 / L
Total cost:       0.517 × ₱65.00 = ₱33.60
Passengers:       3
Per person:       ₱33.60 ÷ 3 = ₱11.20
```

All values update live while the sheet is open.
