class TripSummaryData {
  const TripSummaryData({
    required this.tripId,
    required this.routeLabel,
    required this.startedAt,
    required this.endedAt,
    required this.distanceKm,
    required this.duration,
    required this.fuelEfficiencyKmPerLiter,
    required this.gasPricePerLiter,
    required this.gasUsedLiters,
    required this.totalCost,
    required this.passengerCount,
    required this.perPersonShare,
  });

  final String tripId;
  final String routeLabel;
  final DateTime startedAt;
  final DateTime endedAt;
  final double distanceKm;
  final Duration duration;
  final double fuelEfficiencyKmPerLiter;
  final double gasPricePerLiter;
  final double gasUsedLiters;
  final double totalCost;
  final int passengerCount;
  final double perPersonShare;
}
