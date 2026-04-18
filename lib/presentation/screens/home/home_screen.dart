import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final trips = _demoTrips;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.success,
                    child: Text(
                      'DR',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppStrings.homeGreeting,
                      style: textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    onPressed: () => context.go('/'),
                    icon: const Icon(Icons.logout_rounded),
                    tooltip: 'Logout',
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => context.go('/trip/start'),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text(AppStrings.homeStartTripButton),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    backgroundColor: AppColors.primaryAccent,
                    foregroundColor: AppColors.darkSurface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      AppStrings.homeHistoryTitle,
                      style: textTheme.titleMedium,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go('/history'),
                    child: const Text(AppStrings.homeHistoryCta),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Expanded(
                child: trips.isEmpty
                    ? _HomeEmptyState(message: AppStrings.homeEmptyState)
                    : ListView.builder(
                        itemCount: trips.length,
                        itemBuilder: (context, index) {
                          final trip = trips[index];
                          return _TripHistoryTile(trip: trip);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeEmptyState extends StatelessWidget {
  const _HomeEmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.map_outlined,
              size: 54,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _TripHistoryTile extends StatelessWidget {
  const _TripHistoryTile({required this.trip});

  final _HomeTripInfo trip;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(trip.route, style: textTheme.titleMedium),
            const SizedBox(height: 2),
            Text(trip.meta, style: textTheme.bodyMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('Total: ${trip.total}', style: textTheme.bodyLarge),
                const SizedBox(width: 12),
                Text('Per person: ${trip.share}', style: textTheme.bodyLarge),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeTripInfo {
  const _HomeTripInfo({
    required this.route,
    required this.meta,
    required this.total,
    required this.share,
  });

  final String route;
  final String meta;
  final String total;
  final String share;
}

const _demoTrips = <_HomeTripInfo>[
  _HomeTripInfo(
    route: 'Roxas Ave -> SM City',
    meta: 'Apr 17, 2026 - 3 pax - 6.2 km',
    total: 'PHP 73.80',
    share: 'PHP 24.60',
  ),
  _HomeTripInfo(
    route: 'Lanang -> Abreeza',
    meta: 'Apr 15, 2026 - 2 pax - 4.1 km',
    total: 'PHP 38.80',
    share: 'PHP 19.40',
  ),
  _HomeTripInfo(
    route: 'Bajada -> Matina',
    meta: 'Apr 11, 2026 - 4 pax - 8.4 km',
    total: 'PHP 108.60',
    share: 'PHP 27.15',
  ),
];
