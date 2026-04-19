import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/trip_summary_data.dart';
import 'firebase_bootstrap.dart';

class FirestoreService {
  FirestoreService({bool useFirestore = false, String collectionPath = 'trips'})
    : _useFirestore = useFirestore,
      _collectionPath = collectionPath;

  final bool _useFirestore;
  final String _collectionPath;

  final List<TripSummaryData> _completedTrips = <TripSummaryData>[];

  Future<void> saveCompletedTrip(TripSummaryData trip) async {
    _completedTrips.removeWhere((item) => item.tripId == trip.tripId);
    _completedTrips.insert(0, trip);

    final collection = await _resolveCollection();
    if (collection != null) {
      await collection.doc(trip.tripId).set(_toFirestoreMap(trip));
    }
  }

  Future<List<TripSummaryData>> fetchCompletedTrips() async {
    final collection = await _resolveCollection();
    if (collection != null) {
      try {
        final snapshot = await collection
            .orderBy('endedAtMs', descending: true)
            .get();
        return snapshot.docs
            .map((doc) => _fromFirestoreMap(doc.data()))
            .whereType<TripSummaryData>()
            .toList(growable: false);
      } catch (_) {
        final snapshot = await collection.get();
        final trips =
            snapshot.docs
                .map((doc) => _fromFirestoreMap(doc.data()))
                .whereType<TripSummaryData>()
                .toList(growable: false)
              ..sort((a, b) => b.endedAt.compareTo(a.endedAt));
        return trips;
      }
    }

    return List<TripSummaryData>.unmodifiable(_completedTrips);
  }

  Future<CollectionReference<Map<String, dynamic>>?>
  _resolveCollection() async {
    if (!_useFirestore) {
      return null;
    }

    final initialized = await FirebaseBootstrap.ensureInitialized();
    if (!initialized) {
      return null;
    }

    return FirebaseFirestore.instance.collection(_collectionPath);
  }

  Map<String, Object?> _toFirestoreMap(TripSummaryData trip) {
    return <String, Object?>{
      'tripId': trip.tripId,
      'routeLabel': trip.routeLabel,
      'startedAtMs': trip.startedAt.millisecondsSinceEpoch,
      'endedAtMs': trip.endedAt.millisecondsSinceEpoch,
      'distanceKm': trip.distanceKm,
      'durationSeconds': trip.duration.inSeconds,
      'fuelEfficiencyKmPerLiter': trip.fuelEfficiencyKmPerLiter,
      'gasPricePerLiter': trip.gasPricePerLiter,
      'gasUsedLiters': trip.gasUsedLiters,
      'totalCost': trip.totalCost,
      'passengerCount': trip.passengerCount,
      'perPersonShare': trip.perPersonShare,
    };
  }

  TripSummaryData? _fromFirestoreMap(Map<String, dynamic> map) {
    final tripId = map['tripId'];
    final routeLabel = map['routeLabel'];
    final startedAtMs = map['startedAtMs'];
    final endedAtMs = map['endedAtMs'];

    if (tripId is! String ||
        routeLabel is! String ||
        startedAtMs is! num ||
        endedAtMs is! num) {
      return null;
    }

    return TripSummaryData(
      tripId: tripId,
      routeLabel: routeLabel,
      startedAt: DateTime.fromMillisecondsSinceEpoch(startedAtMs.toInt()),
      endedAt: DateTime.fromMillisecondsSinceEpoch(endedAtMs.toInt()),
      distanceKm: _readDouble(map['distanceKm']),
      duration: Duration(seconds: _readInt(map['durationSeconds'])),
      fuelEfficiencyKmPerLiter: _readDouble(
        map['fuelEfficiencyKmPerLiter'],
        fallback: 12,
      ),
      gasPricePerLiter: _readDouble(map['gasPricePerLiter'], fallback: 65),
      gasUsedLiters: _readDouble(map['gasUsedLiters']),
      totalCost: _readDouble(map['totalCost']),
      passengerCount: _readInt(map['passengerCount'], fallback: 1),
      perPersonShare: _readDouble(map['perPersonShare']),
    );
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
}
