import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/backend_config.dart';
import '../data/models/live_trip_state.dart';
import '../data/models/trip_session_config.dart';
import '../data/models/trip_summary_data.dart';
import '../data/repositories/trip_repository.dart';
import '../data/services/firestore_service.dart';
import '../data/services/gps_service.dart';
import '../data/services/realtime_db_service.dart';

final gpsServiceProvider = Provider<GpsService>((ref) {
  return GpsService(useGeolocator: kUseRealGpsStream);
});

final realtimeDbServiceProvider = Provider<RealtimeDbService>((ref) {
  final service = RealtimeDbService(
    useFirebase: kUseFirebaseBackend,
    activeTripPath: 'active_trips/$kActiveTripDriverId',
  );
  ref.onDispose(service.dispose);
  return service;
});

final firestoreServiceProvider = Provider<FirestoreService>(
  (ref) => FirestoreService(
    useFirestore: kUseFirebaseBackend,
    collectionPath: kTripsCollectionPath,
  ),
);

final tripRepositoryProvider = Provider<TripRepository>((ref) {
  return TripRepository(
    gpsService: ref.read(gpsServiceProvider),
    realtimeDbService: ref.read(realtimeDbServiceProvider),
    firestoreService: ref.read(firestoreServiceProvider),
  );
});

final tripProvider = StateNotifierProvider<TripNotifier, LiveTripState>((ref) {
  final notifier = TripNotifier(repository: ref.read(tripRepositoryProvider));
  return notifier;
});

class TripNotifier extends StateNotifier<LiveTripState> {
  TripNotifier({required TripRepository repository})
    : _repository = repository,
      super(const LiveTripState());

  final TripRepository _repository;
  StreamSubscription<GpsTick>? _gpsSubscription;

  Future<void> startTrip(
    TripSessionConfig config, {
    String routeLabel = 'Current route',
  }) async {
    await _gpsSubscription?.cancel();

    final startedAt = DateTime.now();
    state = _repository.startTripSession(
      config: config,
      startedAt: startedAt,
      routeLabel: routeLabel,
    );

    await _repository.syncActiveTrip(state);

    _gpsSubscription = _repository.createGpsTickStream().listen((tick) async {
      if (!state.isActive) {
        return;
      }

      state = _repository.applyGpsTick(current: state, tick: tick);
      await _repository.syncActiveTrip(state);
    });
  }

  Future<TripSummaryData?> endTrip() async {
    if (!state.isActive) {
      return null;
    }

    await _gpsSubscription?.cancel();
    _gpsSubscription = null;

    final summary = await _repository.endTrip(state);
    state = const LiveTripState();

    return summary;
  }

  @override
  void dispose() {
    _gpsSubscription?.cancel();
    super.dispose();
  }
}
