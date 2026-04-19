import 'dart:async';

import '../models/live_trip_state.dart';

class RealtimeDbService {
  final StreamController<LiveTripState?> _controller =
      StreamController<LiveTripState?>.broadcast();

  LiveTripState? _activeTrip;

  Stream<LiveTripState?> watchActiveTrip() async* {
    yield _activeTrip;
    yield* _controller.stream;
  }

  Future<void> upsertActiveTrip(LiveTripState activeTrip) async {
    _activeTrip = activeTrip;
    if (!_controller.isClosed) {
      _controller.add(activeTrip);
    }
  }

  Future<void> clearActiveTrip() async {
    _activeTrip = null;
    if (!_controller.isClosed) {
      _controller.add(null);
    }
  }

  void dispose() {
    _controller.close();
  }
}
