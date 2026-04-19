class LiveTripState {
  const LiveTripState({
    this.tripId = '',
    this.routeLabel = 'Current route',
    this.startedAt,
    this.distanceKm = 0,
    this.speedKmh = 0,
    this.duration = Duration.zero,
    this.fuelEfficiencyKmPerLiter = 12,
    this.gasPricePerLiter = 65,
    this.passengerCount = 3,
    this.isActive = false,
  });

  final String tripId;
  final String routeLabel;
  final DateTime? startedAt;
  final double distanceKm;
  final double speedKmh;
  final Duration duration;
  final double fuelEfficiencyKmPerLiter;
  final double gasPricePerLiter;
  final int passengerCount;
  final bool isActive;

  double get gasUsedLiters {
    if (fuelEfficiencyKmPerLiter <= 0) {
      return 0;
    }
    return distanceKm / fuelEfficiencyKmPerLiter;
  }

  double get totalCost => gasUsedLiters * gasPricePerLiter;

  double get perPersonShare {
    if (passengerCount <= 0) {
      return 0;
    }
    return totalCost / passengerCount;
  }

  LiveTripState copyWith({
    String? tripId,
    String? routeLabel,
    DateTime? startedAt,
    bool clearStartedAt = false,
    double? distanceKm,
    double? speedKmh,
    Duration? duration,
    double? fuelEfficiencyKmPerLiter,
    double? gasPricePerLiter,
    int? passengerCount,
    bool? isActive,
  }) {
    return LiveTripState(
      tripId: tripId ?? this.tripId,
      routeLabel: routeLabel ?? this.routeLabel,
      startedAt: clearStartedAt ? null : (startedAt ?? this.startedAt),
      distanceKm: distanceKm ?? this.distanceKm,
      speedKmh: speedKmh ?? this.speedKmh,
      duration: duration ?? this.duration,
      fuelEfficiencyKmPerLiter:
          fuelEfficiencyKmPerLiter ?? this.fuelEfficiencyKmPerLiter,
      gasPricePerLiter: gasPricePerLiter ?? this.gasPricePerLiter,
      passengerCount: passengerCount ?? this.passengerCount,
      isActive: isActive ?? this.isActive,
    );
  }
}
