import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/trip_repository.dart';
import '../data/models/trip_summary_data.dart';
import 'trip_provider.dart';

final historyProvider =
    StateNotifierProvider<HistoryNotifier, List<TripSummaryData>>((ref) {
      final notifier = HistoryNotifier(ref.read(tripRepositoryProvider));
      return notifier;
    });

class HistoryNotifier extends StateNotifier<List<TripSummaryData>> {
  HistoryNotifier(this._tripRepository) : super(const <TripSummaryData>[]) {
    refresh();
  }

  final TripRepository _tripRepository;

  Future<void> refresh() async {
    final trips = await _tripRepository.fetchCompletedTrips();
    state = trips;
  }

  Future<void> saveTrip(TripSummaryData trip) async {
    await _tripRepository.saveTripSummary(trip);
    await refresh();
  }
}
