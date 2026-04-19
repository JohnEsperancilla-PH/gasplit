# GaSplit

> Split the ride, not the friendship.

GaSplit is a Flutter-based mobile app for drivers to calculate and split gas costs among passengers in real time. It works like a taxi meter — using live GPS data to compute distance, estimate fuel consumption, and divide the cost equally among everyone in the car.

---

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
- [Documentation](#documentation)

---

## Overview

With rising gas prices, splitting fuel costs fairly among friends has become more important. GaSplit solves this by turning your phone into a live gas meter. The driver sets up a trip with vehicle details and passenger count, and the app tracks distance via GPS — computing everyone's share in real time.

No passenger accounts needed. Driver-only app.

---

## Features

- 🔐 Google Sign-In and Email/Password authentication
- 🗺️ Live GPS tracking with Google Maps
- ⛽ Real-time gas cost meter (distance-based)
- 👥 Per-passenger share displayed live
- 📋 Trip history with full breakdowns
- 📤 Shareable trip summary (via messaging apps)
- 🔔 Push notification on trip end
- 📴 Offline resilience via local cache

---

## Implementation Progress

Last updated: April 19, 2026

| Area | Status | Notes |
|---|---|---|
| App shell and routing | Done | Riverpod app root, go_router routes, base theme |
| Auth screen (`/`) | Done | UI and navigation stubs implemented |
| Home screen (`/home`) | Done | CTA actions, trip preview cards, navigation |
| Start Journey (`/trip/start`) | Done | Inputs, passenger selector, validation, live navigation |
| History (`/history`) | Done | Search/filter, pull-to-refresh, summary navigation |
| Live meter (`/trip/live`) | Done | Real-time UI, formula sheet, passenger split, end-trip flow |
| Trip summary (`/trip/summary/:tripId`) | Pending | Placeholder only |
| Firebase service wiring | Pending | Planned for provider/repository integration |

---

## Tech Stack

| Layer | Technology |
|---|---|
| Frontend | Flutter (latest stable) |
| Authentication | Firebase Auth |
| Database | Cloud Firestore + Firebase Realtime DB |
| Notifications | Firebase Cloud Messaging |
| Maps & GPS | Google Maps Flutter + Geolocator |
| Local Cache | Hive |

---

## Project Structure

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── constants/
│   ├── theme/
│   └── utils/
├── data/
│   ├── models/
│   ├── repositories/
│   └── services/
├── presentation/
│   ├── screens/
│   └── widgets/
└── providers/
```

---

## Getting Started

See [SETUP.md](./SETUP.md) for full installation and Firebase configuration instructions.

---

## Documentation

| File | Description |
|---|---|
| [SETUP.md](./SETUP.md) | Installation, Firebase config, environment setup |
| [ARCHITECTURE.md](./ARCHITECTURE.md) | App structure, data flow, state management |
| [SCREENS.md](./SCREENS.md) | Screen-by-screen UI and feature breakdown |
| [DATA_MODELS.md](./DATA_MODELS.md) | Firestore and Realtime DB schemas |
| [GAS_FORMULA.md](./GAS_FORMULA.md) | Gas cost computation logic |
| [GPS_TRACKING.md](./GPS_TRACKING.md) | GPS implementation and live meter logic |
| [COPILOT_PROMPT.md](./COPILOT_PROMPT.md) | Full Copilot prompt for AI-assisted development |
