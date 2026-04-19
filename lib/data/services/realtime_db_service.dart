import 'dart:async';

import 'package:firebase_database/firebase_database.dart';

import '../models/live_trip_state.dart';
import 'firebase_bootstrap.dart';

class RealtimeDbService {
  RealtimeDbService({
    bool useFirebase = false,
    String activeTripPath = 'active_trips/dev_driver',
  }) : _useFirebase = useFirebase,
       _activeTripPath = activeTripPath;

  final bool _useFirebase;
  final String _activeTripPath;

  final StreamController<LiveTripState?> _controller =
      StreamController<LiveTripState?>.broadcast();

  LiveTripState? _activeTrip;

  Stream<LiveTripState?> watchActiveTrip() async* {
    final reference = await _resolveReference();
    if (reference != null) {
      final snapshot = await reference.get();
      yield _fromRealtimeValue(snapshot.value);
      yield* reference.onValue.map((event) {
        return _fromRealtimeValue(event.snapshot.value);
      });
      return;
    }

    yield _activeTrip;
    yield* _controller.stream;
  }

  Future<void> upsertActiveTrip(LiveTripState activeTrip) async {
    _activeTrip = activeTrip;
    if (!_controller.isClosed) {
      _controller.add(activeTrip);
    }

    final reference = await _resolveReference();
    if (reference != null) {
      await reference.set(_toRealtimeValue(activeTrip));
    }
  }

  Future<void> clearActiveTrip() async {
    _activeTrip = null;
    if (!_controller.isClosed) {
      _controller.add(null);
    }

    final reference = await _resolveReference();
    if (reference != null) {
      await reference.remove();
    }
  }

  void dispose() {
    _controller.close();
  }

  Future<DatabaseReference?> _resolveReference() async {
    if (!_useFirebase) {
      return null;
    }

    final initialized = await FirebaseBootstrap.ensureInitialized();
    if (!initialized) {
      return null;
    }

    return FirebaseDatabase.instance.ref(_activeTripPath);
  }

  Map<String, Object?> _toRealtimeValue(LiveTripState trip) {
    return <String, Object?>{
      'tripId': trip.tripId,
      'routeLabel': trip.routeLabel,
      'startedAtMs': trip.startedAt?.millisecondsSinceEpoch,
      'distanceKm': trip.distanceKm,
      'speedKmh': trip.speedKmh,
      'durationSeconds': trip.duration.inSeconds,
      'fuelEfficiencyKmPerLiter': trip.fuelEfficiencyKmPerLiter,
      'gasPricePerLiter': trip.gasPricePerLiter,
      'passengerCount': trip.passengerCount,
      'isActive': trip.isActive,
      'lastUpdatedMs': DateTime.now().millisecondsSinceEpoch,
    };
  }

  LiveTripState? _fromRealtimeValue(Object? value) {
    if (value is! Map<Object?, Object?>) {
      return null;
    }

    final map = value.map((key, entryValue) {
      return MapEntry(key.toString(), entryValue);
    });

    return LiveTripState(
      tripId: _readString(map['tripId']),
      routeLabel: _readString(map['routeLabel'], fallback: 'Current route'),
      startedAt: _readDateTime(map['startedAtMs']),
      distanceKm: _readDouble(map['distanceKm']),
      speedKmh: _readDouble(map['speedKmh']),
      duration: Duration(seconds: _readInt(map['durationSeconds'])),
      fuelEfficiencyKmPerLiter: _readDouble(
        map['fuelEfficiencyKmPerLiter'],
        fallback: 12,
      ),
      gasPricePerLiter: _readDouble(map['gasPricePerLiter'], fallback: 65),
      passengerCount: _readInt(map['passengerCount'], fallback: 3),
      isActive: _readBool(map['isActive']),
    );
  }

  String _readString(Object? raw, {String fallback = ''}) {
    if (raw is String) {
      return raw;
    }
    return fallback;
  }

  double _readDouble(Object? raw, {double fallback = 0.0}) {
    if (raw is num) {
      return raw.toDouble();
    }
    return fallback;
  }

  int _readInt(Object? raw, {int fallback = 0}) {
    if (raw is num) {
      return raw.toInt();
    }
    return fallback;
  }

  bool _readBool(Object? raw, {bool fallback = false}) {
    if (raw is bool) {
      return raw;
    }
    return fallback;
  }

  DateTime? _readDateTime(Object? raw) {
    if (raw is num) {
      return DateTime.fromMillisecondsSinceEpoch(raw.toInt());
    }
    return null;
  }
}
