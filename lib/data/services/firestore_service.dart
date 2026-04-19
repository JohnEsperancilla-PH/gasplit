import '../models/trip_summary_data.dart';

class FirestoreService {
  final List<TripSummaryData> _completedTrips = <TripSummaryData>[];

  Future<void> saveCompletedTrip(TripSummaryData trip) async {
    _completedTrips.removeWhere((item) => item.tripId == trip.tripId);
    _completedTrips.insert(0, trip);
  }

  Future<List<TripSummaryData>> fetchCompletedTrips() async {
    return List<TripSummaryData>.unmodifiable(_completedTrips);
  }
}
