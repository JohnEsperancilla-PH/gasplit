import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/models/trip_summary_data.dart';
import '../../../providers/history_provider.dart';

class AuthScreen extends ConsumerWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final recentTrips = _buildRecentTrips(ref.watch(recentTripsProvider));

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              const _BrandMark(),
              const SizedBox(height: 18),
              Text(
                AppStrings.appName,
                textAlign: TextAlign.center,
                style: textTheme.titleLarge?.copyWith(
                  fontSize: 34,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.tagline,
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge,
              ),
              const SizedBox(height: 28),
              Text(
                AppStrings.authTitle,
                style: textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: () => context.go('/home'),
                icon: const Icon(Icons.g_mobiledata_rounded, size: 24),
                label: const Text(AppStrings.authGoogleButton),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  backgroundColor: AppColors.primaryAccent,
                  foregroundColor: AppColors.darkSurface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => context.go('/home'),
                icon: const Icon(Icons.email_outlined),
                label: const Text(AppStrings.authEmailButton),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.border, width: 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppStrings.authRecentTripsTitle,
                    style: textTheme.titleMedium,
                  ),
                  Text(
                    AppStrings.authRecentTripsSubtitle,
                    style: textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...recentTrips.map(_RecentTripTile.new),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 78,
        height: 78,
        decoration: const BoxDecoration(
          color: AppColors.primaryAccent,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.local_gas_station_rounded,
          size: 34,
          color: AppColors.darkSurface,
        ),
      ),
    );
  }
}

class _RecentTripInfo {
  const _RecentTripInfo({
    required this.route,
    required this.meta,
    required this.share,
  });

  final String route;
  final String meta;
  final String share;
}

class _RecentTripTile extends StatelessWidget {
  const _RecentTripTile(this.trip);

  final _RecentTripInfo trip;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(trip.route, style: textTheme.titleMedium),
                  const SizedBox(height: 3),
                  Text(trip.meta, style: textTheme.bodyMedium),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              trip.share,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

List<_RecentTripInfo> _buildRecentTrips(List<TripSummaryData> recentTrips) {
  return recentTrips.map(_recentTripFromSummary).toList(growable: false);
}

_RecentTripInfo _recentTripFromSummary(TripSummaryData summary) {
  final routeLabel = summary.routeLabel.trim().isEmpty
      ? AppStrings.tripSummaryRouteFallback
      : summary.routeLabel;

  return _RecentTripInfo(
    route: routeLabel,
    meta:
        '${_formatDateTime(summary.endedAt)} - ${summary.passengerCount} pax - ${summary.distanceKm.toStringAsFixed(1)} km',
    share: _formatPeso(summary.perPersonShare),
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
