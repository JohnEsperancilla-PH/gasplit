import 'dart:math';

class GpsTick {
  const GpsTick({
    required this.distanceDeltaKm,
    required this.speedKmh,
    required this.timestamp,
  });

  final double distanceDeltaKm;
  final double speedKmh;
  final DateTime timestamp;
}

class GpsService {
  final Random _random = Random();

  Stream<GpsTick> createTripTickStream() {
    return Stream<GpsTick>.periodic(const Duration(seconds: 1), (_) {
      final distanceDeltaKm = 0.0035 + (_random.nextDouble() * 0.0065);
      final speedKmh = (distanceDeltaKm * 3600).clamp(0.0, 120.0).toDouble();

      return GpsTick(
        distanceDeltaKm: distanceDeltaKm,
        speedKmh: speedKmh,
        timestamp: DateTime.now(),
      );
    });
  }
}
