import 'dart:math';

import 'package:geolocator/geolocator.dart';

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
  GpsService({bool useGeolocator = false, Random? random})
    : _useGeolocator = useGeolocator,
      _random = random ?? Random();

  final bool _useGeolocator;
  final Random _random;

  static const LocationSettings _locationSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 5,
  );

  Stream<GpsTick> createTripTickStream() {
    if (_useGeolocator) {
      return _createGeolocatorTripTickStream();
    }

    return _createSimulatedTripTickStream();
  }

  Stream<GpsTick> _createSimulatedTripTickStream() {
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

  Stream<GpsTick> _createGeolocatorTripTickStream() async* {
    final canUseGeolocator = await _hasLocationPermission();
    if (!canUseGeolocator) {
      yield* _createSimulatedTripTickStream();
      return;
    }

    Position? lastPosition;
    await for (final position in Geolocator.getPositionStream(
      locationSettings: _locationSettings,
    )) {
      final timestamp = position.timestamp ?? DateTime.now();
      final distanceDeltaKm = _distanceDeltaKm(
        previous: lastPosition,
        current: position,
      );
      final speedKmh = position.speed > 0 ? position.speed * 3.6 : 0.0;

      lastPosition = position;

      yield GpsTick(
        distanceDeltaKm: distanceDeltaKm,
        speedKmh: speedKmh.clamp(0.0, 140.0).toDouble(),
        timestamp: timestamp,
      );
    }
  }

  Future<bool> _hasLocationPermission() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return false;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    } catch (_) {
      return false;
    }
  }

  double _distanceDeltaKm({
    required Position? previous,
    required Position current,
  }) {
    if (previous == null) {
      return 0.0;
    }

    final meters = Geolocator.distanceBetween(
      previous.latitude,
      previous.longitude,
      current.latitude,
      current.longitude,
    );

    if (!meters.isFinite || meters <= 0) {
      return 0.0;
    }

    return meters / 1000;
  }
}
