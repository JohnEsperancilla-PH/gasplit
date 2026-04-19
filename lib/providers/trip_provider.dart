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
import 'auth_provider.dart';

final gpsServiceProvider = Provider<GpsService>((ref) {
  return GpsService(useGeolocator: kUseRealGpsStream);
});

final authenticatedUidProvider = Provider<String>((ref) {
  final authUser = ref.watch(authStateProvider).valueOrNull;
  if (authUser != null && authUser.uid.trim().isNotEmpty) {
    return authUser.uid;
  }
  return kActiveTripDriverId;
});

final activeTripPathProvider = Provider<String>((ref) {
  final uid = ref.watch(authenticatedUidProvider);
  return _joinPath(<String>[kActiveTripsPath, uid]);
});

final tripsCollectionPathProvider = Provider<String>((ref) {
  final uid = ref.watch(authenticatedUidProvider);
  return _joinPath(<String>[kUsersCollectionPath, uid, kTripsCollectionPath]);
});

final realtimeDbServiceProvider = Provider<RealtimeDbService>((ref) {
  final service = RealtimeDbService(
    useFirebase: kUseFirebaseBackend,
    activeTripPath: ref.watch(activeTripPathProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});

final firestoreServiceProvider = Provider<FirestoreService>(
  (ref) => FirestoreService(
    useFirestore: kUseFirebaseBackend,
    collectionPath: ref.watch(tripsCollectionPathProvider),
  ),
);

final tripRepositoryProvider = Provider<TripRepository>((ref) {
  return TripRepository(
    gpsService: ref.watch(gpsServiceProvider),
    realtimeDbService: ref.watch(realtimeDbServiceProvider),
    firestoreService: ref.watch(firestoreServiceProvider),
  );
});

final tripProvider = StateNotifierProvider<TripNotifier, LiveTripState>((ref) {
  final notifier = TripNotifier(repository: ref.watch(tripRepositoryProvider));
  return notifier;
});

class TripNotifier extends StateNotifier<LiveTripState> {
  TripNotifier({required TripRepository repository})
    : _repository = repository,
      super(const LiveTripState()) {
    _restoreActiveTrip();
  }

  final TripRepository _repository;
  StreamSubscription<GpsTick>? _gpsSubscription;

  Future<void> _restoreActiveTrip() async {
    try {
      final activeTrip = await _repository.watchActiveTrip().first;
      if (activeTrip != null && activeTrip.isActive) {
        state = activeTrip;
      }
    } catch (_) {
      // Fallback mode may not have a persisted active trip.
    }
  }

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

String _joinPath(List<String> segments) {
  return segments
      .map((segment) => segment.trim())
      .where((segment) => segment.isNotEmpty)
      .join('/');
}
