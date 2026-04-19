class TripSessionConfig {
  const TripSessionConfig({
    required this.fuelEfficiencyKmPerLiter,
    required this.gasPricePerLiter,
    required this.passengerCount,
  });

  final double fuelEfficiencyKmPerLiter;
  final double gasPricePerLiter;
  final int passengerCount;
}
