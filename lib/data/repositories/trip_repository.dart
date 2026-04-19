import '../models/live_trip_state.dart';
import '../models/trip_session_config.dart';
import '../models/trip_summary_data.dart';
import '../services/firestore_service.dart';
import '../services/gps_service.dart';
import '../services/realtime_db_service.dart';

class TripRepository {
  TripRepository({
    required GpsService gpsService,
    required RealtimeDbService realtimeDbService,
    required FirestoreService firestoreService,
  }) : _gpsService = gpsService,
       _realtimeDbService = realtimeDbService,
       _firestoreService = firestoreService;

  final GpsService _gpsService;
  final RealtimeDbService _realtimeDbService;
  final FirestoreService _firestoreService;

  Stream<GpsTick> createGpsTickStream() {
    return _gpsService.createTripTickStream();
  }

  LiveTripState startTripSession({
    required TripSessionConfig config,
    required DateTime startedAt,
    String routeLabel = 'Current route',
  }) {
    return LiveTripState(
      tripId: 'trip_${startedAt.millisecondsSinceEpoch}',
      routeLabel: routeLabel,
      startedAt: startedAt,
      distanceKm: 0,
      speedKmh: 0,
      duration: Duration.zero,
      fuelEfficiencyKmPerLiter: config.fuelEfficiencyKmPerLiter,
      gasPricePerLiter: config.gasPricePerLiter,
      passengerCount: config.passengerCount,
      isActive: true,
    );
  }

  LiveTripState applyGpsTick({
    required LiveTripState current,
    required GpsTick tick,
  }) {
    if (!current.isActive) {
      return current;
    }

    final startedAt = current.startedAt ?? tick.timestamp;
    final deltaKm = tick.distanceDeltaKm > 0.5 ? 0.0 : tick.distanceDeltaKm;
    final duration = tick.timestamp.difference(startedAt);

    return current.copyWith(
      distanceKm: current.distanceKm + deltaKm,
      speedKmh: tick.speedKmh < 0 ? 0 : tick.speedKmh,
      duration: duration.isNegative ? Duration.zero : duration,
    );
  }

  Future<void> syncActiveTrip(LiveTripState activeTrip) {
    return _realtimeDbService.upsertActiveTrip(activeTrip);
  }

  Stream<LiveTripState?> watchActiveTrip() {
    return _realtimeDbService.watchActiveTrip();
  }

  Future<TripSummaryData> endTrip(
    LiveTripState activeTrip, {
    DateTime? endedAt,
  }) async {
    final resolvedEndedAt = endedAt ?? DateTime.now();
    final startedAt = activeTrip.startedAt ?? resolvedEndedAt;
    final passengerCount = activeTrip.passengerCount <= 0
        ? 1
        : activeTrip.passengerCount;

    final summary = TripSummaryData(
      tripId: activeTrip.tripId,
      routeLabel: activeTrip.routeLabel,
      startedAt: startedAt,
      endedAt: resolvedEndedAt,
      distanceKm: activeTrip.distanceKm,
      duration: activeTrip.duration > Duration.zero
          ? activeTrip.duration
          : resolvedEndedAt.difference(startedAt),
      fuelEfficiencyKmPerLiter: activeTrip.fuelEfficiencyKmPerLiter,
      gasPricePerLiter: activeTrip.gasPricePerLiter,
      gasUsedLiters: activeTrip.gasUsedLiters,
      totalCost: activeTrip.totalCost,
      passengerCount: passengerCount,
      perPersonShare: activeTrip.totalCost / passengerCount,
    );

    await _firestoreService.saveCompletedTrip(summary);
    await _realtimeDbService.clearActiveTrip();

    return summary;
  }

  Future<List<TripSummaryData>> fetchCompletedTrips() {
    return _firestoreService.fetchCompletedTrips();
  }

  Future<void> saveTripSummary(TripSummaryData summary) {
    return _firestoreService.saveCompletedTrip(summary);
  }
}
