import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/trip_summary_data.dart';
import '../data/repositories/trip_repository.dart';
import 'auth_provider.dart';
import 'trip_provider.dart';

final historyProvider =
    StateNotifierProvider<HistoryNotifier, List<TripSummaryData>>((ref) {
      final notifier = HistoryNotifier(ref.watch(tripRepositoryProvider));

      final initialUser = ref.watch(authStateProvider).valueOrNull;
      if (initialUser != null) {
        notifier.refresh();
      }

      ref.listen(authStateProvider, (previous, next) {
        final previousUser = previous?.valueOrNull;
        final nextUser = next.valueOrNull;
        if (nextUser == null) {
          notifier.clear();
          return;
        }

        if (nextUser.uid != previousUser?.uid) {
          notifier.refresh();
        }
      });
      return notifier;
    });

final mergedHistoryProvider = Provider<List<TripSummaryData>>((ref) {
  final savedTrips = ref.watch(historyProvider);
  final mergedById = <String, TripSummaryData>{
    for (final trip in savedTrips) trip.tripId: trip,
  };

  for (final trip in _seedTrips) {
    mergedById.putIfAbsent(trip.tripId, () => trip);
  }

  final mergedTrips = mergedById.values.toList()
    ..sort((a, b) => b.endedAt.compareTo(a.endedAt));

  return mergedTrips;
});

final recentTripsProvider = Provider<List<TripSummaryData>>((ref) {
  return ref.watch(mergedHistoryProvider).take(3).toList(growable: false);
});

class HistoryNotifier extends StateNotifier<List<TripSummaryData>> {
  HistoryNotifier(this._tripRepository) : super(const <TripSummaryData>[]);

  final TripRepository _tripRepository;

  Future<void> refresh() async {
    try {
      final trips = await _tripRepository.fetchCompletedTrips();
      state = trips;
    } catch (_) {
      // Avoid crashing when backend mode is enabled but auth is not ready yet.
      state = const <TripSummaryData>[];
    }
  }

  void clear() {
    state = const <TripSummaryData>[];
  }

  Future<void> saveTrip(TripSummaryData trip) async {
    await _tripRepository.saveTripSummary(trip);
    await refresh();
  }
}

final List<TripSummaryData> _seedTrips = <TripSummaryData>[
  TripSummaryData(
    tripId: 'trip_20260417_1',
    routeLabel: 'Roxas Ave -> SM City',
    startedAt: DateTime(2026, 4, 17, 18),
    endedAt: DateTime(2026, 4, 17, 18, 12),
    distanceKm: 6.2,
    duration: Duration(minutes: 12),
    fuelEfficiencyKmPerLiter: 12,
    gasPricePerLiter: 65,
    gasUsedLiters: 1.135384615,
    totalCost: 73.8,
    passengerCount: 3,
    perPersonShare: 24.6,
  ),
  TripSummaryData(
    tripId: 'trip_20260416_1',
    routeLabel: 'Bajada -> Matina',
    startedAt: DateTime(2026, 4, 16, 7, 45),
    endedAt: DateTime(2026, 4, 16, 8, 5),
    distanceKm: 8.4,
    duration: Duration(minutes: 20),
    fuelEfficiencyKmPerLiter: 12,
    gasPricePerLiter: 65,
    gasUsedLiters: 1.670769231,
    totalCost: 108.6,
    passengerCount: 4,
    perPersonShare: 27.15,
  ),
  TripSummaryData(
    tripId: 'trip_20260415_1',
    routeLabel: 'Lanang -> Abreeza',
    startedAt: DateTime(2026, 4, 15, 7, 29),
    endedAt: DateTime(2026, 4, 15, 7, 38),
    distanceKm: 4.1,
    duration: Duration(minutes: 9),
    fuelEfficiencyKmPerLiter: 12,
    gasPricePerLiter: 65,
    gasUsedLiters: 0.596923077,
    totalCost: 38.8,
    passengerCount: 2,
    perPersonShare: 19.4,
  ),
  TripSummaryData(
    tripId: 'trip_20260414_1',
    routeLabel: 'SM Ecoland -> Downtown',
    startedAt: DateTime(2026, 4, 14, 19, 11),
    endedAt: DateTime(2026, 4, 14, 19, 25),
    distanceKm: 5.5,
    duration: Duration(minutes: 14),
    fuelEfficiencyKmPerLiter: 12,
    gasPricePerLiter: 65,
    gasUsedLiters: 0.9,
    totalCost: 58.5,
    passengerCount: 3,
    perPersonShare: 19.5,
  ),
  TripSummaryData(
    tripId: 'trip_20260413_1',
    routeLabel: 'Azuela Cove -> Buhangin',
    startedAt: DateTime(2026, 4, 13, 6, 21),
    endedAt: DateTime(2026, 4, 13, 6, 45),
    distanceKm: 10.2,
    duration: Duration(minutes: 24),
    fuelEfficiencyKmPerLiter: 12,
    gasPricePerLiter: 65,
    gasUsedLiters: 2.092307692,
    totalCost: 136,
    passengerCount: 5,
    perPersonShare: 27.2,
  ),
  TripSummaryData(
    tripId: 'trip_20260412_1',
    routeLabel: 'Buhangin -> Ulas',
    startedAt: DateTime(2026, 4, 12, 20, 46),
    endedAt: DateTime(2026, 4, 12, 21, 3),
    distanceKm: 7.8,
    duration: Duration(minutes: 17),
    fuelEfficiencyKmPerLiter: 12,
    gasPricePerLiter: 65,
    gasUsedLiters: 1.292307692,
    totalCost: 84,
    passengerCount: 2,
    perPersonShare: 42,
  ),
  TripSummaryData(
    tripId: 'trip_20260411_1',
    routeLabel: 'Matina Crossing -> Mintal',
    startedAt: DateTime(2026, 4, 11, 16, 40),
    endedAt: DateTime(2026, 4, 11, 17, 9),
    distanceKm: 11.3,
    duration: Duration(minutes: 29),
    fuelEfficiencyKmPerLiter: 12,
    gasPricePerLiter: 65,
    gasUsedLiters: 2.264615385,
    totalCost: 147.2,
    passengerCount: 4,
    perPersonShare: 36.8,
  ),
];
