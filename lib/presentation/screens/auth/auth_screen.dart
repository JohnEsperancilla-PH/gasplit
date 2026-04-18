import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

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
              ..._demoTrips.map(_RecentTripTile.new),
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

const _demoTrips = <_RecentTripInfo>[
  _RecentTripInfo(
    route: 'Roxas Ave -> SM City',
    meta: 'Apr 17, 2026 - 3 pax - 6.2 km',
    share: 'PHP 24.60',
  ),
  _RecentTripInfo(
    route: 'Lanang -> Abreeza',
    meta: 'Apr 15, 2026 - 2 pax - 4.1 km',
    share: 'PHP 19.40',
  ),
  _RecentTripInfo(
    route: 'Bajada -> Matina',
    meta: 'Apr 11, 2026 - 4 pax - 8.4 km',
    share: 'PHP 27.15',
  ),
];
