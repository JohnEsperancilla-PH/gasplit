import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/models/live_trip_state.dart';
import '../../../data/models/trip_session_config.dart';
import '../../../data/models/trip_summary_data.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/history_provider.dart';
import '../../../providers/trip_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final activeTrip = ref.watch(tripProvider);
    final hasActiveTrip = activeTrip.isActive;
    final trips = _buildHomeTrips(ref.watch(recentTripsProvider));

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
                    onPressed: () async {
                      await ref.read(authControllerProvider).signOut();
                      if (!context.mounted) {
                        return;
                      }
                      context.go('/');
                    },
                    icon: const Icon(Icons.logout_rounded),
                    tooltip: AppStrings.homeLogoutTooltip,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (hasActiveTrip) {
                      context.go(
                        '/trip/live',
                        extra: _configFromLiveTrip(activeTrip),
                      );
                      return;
                    }

                    context.go('/trip/start');
                  },
                  icon: Icon(
                    hasActiveTrip
                        ? Icons.play_circle_fill_rounded
                        : Icons.play_arrow_rounded,
                  ),
                  label: Text(
                    hasActiveTrip
                        ? AppStrings.homeResumeTripButton
                        : AppStrings.homeStartTripButton,
                  ),
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
              if (hasActiveTrip) ...[
                const SizedBox(height: 12),
                _ActiveTripCard(trip: activeTrip),
              ],
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
                          return _TripHistoryTile(
                            trip: trip,
                            onTap: () => context.go(
                              '/trip/summary/${trip.tripId}',
                              extra: trip.summaryData,
                            ),
                          );
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

class _ActiveTripCard extends StatelessWidget {
  const _ActiveTripCard({required this.trip});

  final LiveTripState trip;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppStrings.homeActiveTripTitle, style: textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              AppStrings.homeActiveTripSubtitle,
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                Text(
                  '${AppStrings.homeActiveTripDistanceLabel}: ${trip.distanceKm.toStringAsFixed(2)} km',
                  style: textTheme.bodyLarge,
                ),
                Text(
                  '${AppStrings.homeActiveTripTotalLabel}: ${_formatPeso(trip.totalCost)}',
                  style: textTheme.bodyLarge,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TripHistoryTile extends StatelessWidget {
  const _TripHistoryTile({required this.trip, required this.onTap});

  final _HomeTripInfo trip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
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
      ),
    );
  }
}

class _HomeTripInfo {
  const _HomeTripInfo({
    required this.tripId,
    required this.route,
    required this.meta,
    required this.total,
    required this.share,
    this.summaryData,
  });

  final String tripId;
  final String route;
  final String meta;
  final String total;
  final String share;
  final TripSummaryData? summaryData;
}

List<_HomeTripInfo> _buildHomeTrips(List<TripSummaryData> recentTrips) {
  return recentTrips.map(_homeTripFromSummary).toList(growable: false);
}

TripSessionConfig _configFromLiveTrip(LiveTripState trip) {
  return TripSessionConfig(
    fuelEfficiencyKmPerLiter: trip.fuelEfficiencyKmPerLiter,
    gasPricePerLiter: trip.gasPricePerLiter,
    passengerCount: trip.passengerCount,
  );
}

_HomeTripInfo _homeTripFromSummary(TripSummaryData summary) {
  final routeLabel = summary.routeLabel.trim().isEmpty
      ? AppStrings.tripSummaryRouteFallback
      : summary.routeLabel;

  return _HomeTripInfo(
    tripId: summary.tripId,
    route: routeLabel,
    meta:
        '${_formatDateTime(summary.endedAt)} - ${summary.passengerCount} pax - ${summary.distanceKm.toStringAsFixed(1)} km',
    total: _formatPeso(summary.totalCost),
    share: _formatPeso(summary.perPersonShare),
    summaryData: summary,
  );
}

String _formatDateTime(DateTime value) {
  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  final month = months[value.month - 1];
  final hour24 = value.hour;
  final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
  final minute = value.minute.toString().padLeft(2, '0');
  final period = hour24 >= 12 ? 'PM' : 'AM';

  return '$month ${value.day}, ${value.year} $hour12:$minute $period';
}

String _formatPeso(double amount) {
  return 'PHP ${amount.toStringAsFixed(2)}';
}
