import 'package:go_router/go_router.dart';

import '../../data/models/trip_session_config.dart';
import '../../presentation/screens/auth/auth_screen.dart';
import '../../presentation/screens/history/history_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/trip/live_meter_screen.dart';
import '../../presentation/screens/trip/start_trip_screen.dart';
import '../../presentation/screens/trip/trip_summary_screen.dart';

class AppRouter {
  const AppRouter._();

  static GoRouter createRouter() {
    return GoRouter(
      routes: [
        GoRoute(path: '/', builder: (context, state) => const AuthScreen()),
        GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
        GoRoute(
          path: '/trip/start',
          builder: (context, state) => const StartTripScreen(),
        ),
        GoRoute(
          path: '/trip/live',
          builder: (context, state) {
            final config = state.extra is TripSessionConfig
                ? state.extra! as TripSessionConfig
                : const TripSessionConfig(
                    fuelEfficiencyKmPerLiter: 12,
                    gasPricePerLiter: 65,
                    passengerCount: 3,
                  );
            return LiveMeterScreen(config: config);
          },
        ),
        GoRoute(
          path: '/trip/summary/:id',
          builder: (context, state) {
            final tripId = state.pathParameters['id'] ?? '';
            return TripSummaryScreen(tripId: tripId);
          },
        ),
        GoRoute(
          path: '/history',
          builder: (context, state) => const HistoryScreen(),
        ),
      ],
    );
  }
}
