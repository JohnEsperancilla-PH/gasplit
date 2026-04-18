# Gas Cost Formula

This document explains how GaSplit computes gas costs in real time and how each value is derived.

---

## Core Formula

```
Gas Used (L)     = Distance (km) ÷ Fuel Efficiency (km/L)
Total Gas Cost   = Gas Used (L) × Gas Price per Liter (₱)
Per Person Share = Total Gas Cost ÷ Number of Passengers
```

---

## Variables

| Variable | Source | Unit |
|---|---|---|
| `distanceKm` | GPS (accumulated from location updates) | km |
| `fuelEfficiency` | Driver input at trip start | km/L |
| `gasPricePerLiter` | Driver input at trip start | ₱/L |
| `passengerCount` | Driver input at trip start | integer |

---

## Step-by-Step Example

| Step | Calculation | Result |
|---|---|---|
| Distance traveled | GPS tracked | 6.2 km |
| Gas used | 6.2 ÷ 12 km/L | 0.517 L |
| Total cost | 0.517 × ₱65.00 | ₱33.60 |
| Per person (3 pax) | ₱33.60 ÷ 3 | ₱11.20 |

---

## Dart Implementation

```dart
class GasCalculator {

  /// Liters of fuel consumed for a given distance
  static double gasUsed({
    required double distanceKm,
    required double fuelEfficiencyKmPerLiter,
  }) {
    if (fuelEfficiencyKmPerLiter <= 0) return 0;
    return distanceKm / fuelEfficiencyKmPerLiter;
  }

  /// Total gas cost in Philippine Peso
  static double totalCost({
    required double gasUsedLiters,
    required double gasPricePerLiter,
  }) {
    return gasUsedLiters * gasPricePerLiter;
  }

  /// Each passenger's share
  static double perPersonShare({
    required double totalCost,
    required int passengerCount,
  }) {
    if (passengerCount <= 0) return 0;
    return totalCost / passengerCount;
  }

  /// Convenience method — compute everything at once
  static TripCost compute({
    required double distanceKm,
    required double fuelEfficiencyKmPerLiter,
    required double gasPricePerLiter,
    required int passengerCount,
  }) {
    final used = gasUsed(
      distanceKm: distanceKm,
      fuelEfficiencyKmPerLiter: fuelEfficiencyKmPerLiter,
    );
    final cost = totalCost(
      gasUsedLiters: used,
      gasPricePerLiter: gasPricePerLiter,
    );
    final share = perPersonShare(
      totalCost: cost,
      passengerCount: passengerCount,
    );
    return TripCost(
      gasUsedLiters: used,
      totalCost: cost,
      perPersonShare: share,
    );
  }
}

class TripCost {
  final double gasUsedLiters;
  final double totalCost;
  final double perPersonShare;

  const TripCost({
    required this.gasUsedLiters,
    required this.totalCost,
    required this.perPersonShare,
  });
}
```

---

## Real-Time Updates

The formula recalculates on every GPS update. Only `distanceKm` changes during a trip — the other inputs remain fixed.

```dart
// Called inside TripNotifier on each position update
void _recalculate() {
  final result = GasCalculator.compute(
    distanceKm: state.distanceKm,
    fuelEfficiencyKmPerLiter: state.fuelEfficiency,
    gasPricePerLiter: state.gasPricePerLiter,
    passengerCount: state.passengerCount,
  );

  state = state.copyWith(
    gasUsedLiters: result.gasUsedLiters,
    totalCost: result.totalCost,
    perPersonShare: result.perPersonShare,
  );
}
```

---

## Currency Formatting

All monetary values are displayed in Philippine Peso with 2 decimal places.

```dart
import 'package:intl/intl.dart';

final _pesoFormatter = NumberFormat.currency(
  locale: 'fil_PH',
  symbol: '₱',
  decimalDigits: 2,
);

String formatPeso(double amount) => _pesoFormatter.format(amount);

// Usage
formatPeso(24.6)   // → "₱24.60"
formatPeso(1500.0) // → "₱1,500.00"
```

---

## Edge Cases

| Scenario | Handling |
|---|---|
| Fuel efficiency set to 0 | Return 0 to avoid divide-by-zero |
| Passenger count set to 0 | Return 0, validated before trip start |
| GPS jumps (signal spike) | Distance delta capped at 0.5 km per update |
| Very short trip (< 0.1 km) | Still calculated normally, no minimum |
| App crash mid-trip | Distance and cost restored from Hive cache |

---

## Notes on Accuracy

GaSplit uses a simplified constant-efficiency model. In reality, fuel consumption varies with:

- Vehicle speed (highway vs. city driving)
- Air conditioning usage
- Road incline
- Vehicle load

A future version could use real-time OBD-II data via Bluetooth for exact consumption figures. For now, the driver's input provides a practical approximation.
