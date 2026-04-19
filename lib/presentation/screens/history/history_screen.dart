import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../data/models/trip_summary_data.dart';
import '../../../providers/history_provider.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  int _visibleCount = 5;
  int _latestFilteredCount = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<_HistoryTrip> _filterTrips(List<_HistoryTrip> trips) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return trips;
    }

    return trips.where((trip) {
      final route = trip.route.toLowerCase();
      final date = _formatDateTime(trip.dateTime).toLowerCase();
      return route.contains(query) || date.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final savedTrips = ref.watch(historyProvider);
    final allTrips = _buildAllTrips(savedTrips);
    final filteredTrips = _filterTrips(allTrips);
    _latestFilteredCount = filteredTrips.length;
    final visibleTrips = filteredTrips.take(_visibleCount).toList();

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.historyTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                onChanged: (_) {
                  setState(() {
                    _visibleCount = 5;
                  });
                },
                decoration: const InputDecoration(
                  hintText: AppStrings.historySearchHint,
                  prefixIcon: Icon(Icons.search_rounded),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: filteredTrips.isEmpty
                    ? Center(
                        child: Text(
                          _searchController.text.trim().isEmpty
                              ? AppStrings.historyEmptyAll
                              : AppStrings.historyEmptyFiltered,
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _refresh,
                        child: ListView.builder(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount:
                              visibleTrips.length +
                              (visibleTrips.length < filteredTrips.length
                                  ? 1
                                  : 0),
                          itemBuilder: (context, index) {
                            if (index >= visibleTrips.length) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            }

                            final trip = visibleTrips[index];
                            return _HistoryTripTile(
                              trip: trip,
                              onTap: () => context.go(
                                '/trip/summary/${trip.tripId}',
                                extra: trip.summaryData,
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleScroll() {
    final filteredCount = _latestFilteredCount;
    if (filteredCount <= _visibleCount) {
      return;
    }

    if (_scrollController.position.extentAfter < 180) {
      setState(() {
        _visibleCount = (_visibleCount + 5).clamp(5, filteredCount);
      });
    }
  }

  Future<void> _refresh() async {
    await ref.read(historyProvider.notifier).refresh();
    if (!mounted) {
      return;
    }
    setState(() {
      _visibleCount = 5;
    });
  }

  List<_HistoryTrip> _buildAllTrips(List<TripSummaryData> savedTrips) {
    final mergedById = <String, _HistoryTrip>{
      for (final trip in savedTrips) trip.tripId: _historyTripFromSummary(trip),
    };

    for (final trip in _seedTrips) {
      mergedById.putIfAbsent(trip.tripId, () => trip);
    }

    final merged = mergedById.values.toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
    return merged;
  }
}

class _HistoryTripTile extends StatelessWidget {
  const _HistoryTripTile({required this.trip, required this.onTap});

  final _HistoryTrip trip;
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
              Text(_formatDateTime(trip.dateTime), style: textTheme.bodyMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 6,
                children: [
                  Text(
                    '${AppStrings.historyPassengersLabel}: ${trip.passengerCount}',
                    style: textTheme.bodyLarge,
                  ),
                  Text(
                    '${AppStrings.historyDistanceLabel}: ${trip.distanceKm.toStringAsFixed(1)} km',
                    style: textTheme.bodyLarge,
                  ),
                  Text(
                    '${AppStrings.historyDurationLabel}: ${trip.durationText}',
                    style: textTheme.bodyLarge,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${AppStrings.historyTotalLabel}: ${trip.totalCostText}',
                      style: textTheme.bodyLarge,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${AppStrings.historyPerPersonLabel}: ${trip.perPersonText}',
                      style: textTheme.bodyLarge,
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryTrip {
  _HistoryTrip({
    required this.tripId,
    required this.route,
    required this.dateTime,
    required this.passengerCount,
    required this.distanceKm,
    required this.durationText,
    required this.totalCostText,
    required this.perPersonText,
    this.summaryData,
  });

  final String tripId;
  final String route;
  final DateTime dateTime;
  final int passengerCount;
  final double distanceKm;
  final String durationText;
  final String totalCostText;
  final String perPersonText;
  final TripSummaryData? summaryData;
}

_HistoryTrip _historyTripFromSummary(TripSummaryData summary) {
  final route = summary.routeLabel.trim().isEmpty
      ? AppStrings.tripSummaryRouteFallback
      : summary.routeLabel;

  return _HistoryTrip(
    tripId: summary.tripId,
    route: route,
    dateTime: summary.endedAt,
    passengerCount: summary.passengerCount,
    distanceKm: summary.distanceKm,
    durationText: _formatDuration(summary.duration),
    totalCostText: _formatPeso(summary.totalCost),
    perPersonText: _formatPeso(summary.perPersonShare),
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

String _formatDuration(Duration value) {
  if (value.inHours > 0) {
    final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    return '${value.inHours}h ${minutes}m';
  }

  final minutes = value.inMinutes <= 0 ? 1 : value.inMinutes;
  return '$minutes min';
}

String _formatPeso(double amount) {
  return 'PHP ${amount.toStringAsFixed(2)}';
}

final _seedTrips = <_HistoryTrip>[
  _HistoryTrip(
    tripId: 'trip_20260417_1',
    route: 'Roxas Ave -> SM City',
    dateTime: DateTime(2026, 4, 17, 18, 12),
    passengerCount: 3,
    distanceKm: 6.2,
    durationText: '12 min',
    totalCostText: 'PHP 73.80',
    perPersonText: 'PHP 24.60',
  ),
  _HistoryTrip(
    tripId: 'trip_20260416_1',
    route: 'Bajada -> Matina',
    dateTime: DateTime(2026, 4, 16, 8, 5),
    passengerCount: 4,
    distanceKm: 8.4,
    durationText: '20 min',
    totalCostText: 'PHP 108.60',
    perPersonText: 'PHP 27.15',
  ),
  _HistoryTrip(
    tripId: 'trip_20260415_1',
    route: 'Lanang -> Abreeza',
    dateTime: DateTime(2026, 4, 15, 7, 38),
    passengerCount: 2,
    distanceKm: 4.1,
    durationText: '9 min',
    totalCostText: 'PHP 38.80',
    perPersonText: 'PHP 19.40',
  ),
  _HistoryTrip(
    tripId: 'trip_20260414_1',
    route: 'SM Ecoland -> Downtown',
    dateTime: DateTime(2026, 4, 14, 19, 25),
    passengerCount: 3,
    distanceKm: 5.5,
    durationText: '14 min',
    totalCostText: 'PHP 58.50',
    perPersonText: 'PHP 19.50',
  ),
  _HistoryTrip(
    tripId: 'trip_20260413_1',
    route: 'Azuela Cove -> Buhangin',
    dateTime: DateTime(2026, 4, 13, 6, 45),
    passengerCount: 5,
    distanceKm: 10.2,
    durationText: '24 min',
    totalCostText: 'PHP 136.00',
    perPersonText: 'PHP 27.20',
  ),
  _HistoryTrip(
    tripId: 'trip_20260412_1',
    route: 'Buhangin -> Ulas',
    dateTime: DateTime(2026, 4, 12, 21, 3),
    passengerCount: 2,
    distanceKm: 7.8,
    durationText: '17 min',
    totalCostText: 'PHP 84.00',
    perPersonText: 'PHP 42.00',
  ),
  _HistoryTrip(
    tripId: 'trip_20260411_1',
    route: 'Matina Crossing -> Mintal',
    dateTime: DateTime(2026, 4, 11, 17, 9),
    passengerCount: 4,
    distanceKm: 11.3,
    durationText: '29 min',
    totalCostText: 'PHP 147.20',
    perPersonText: 'PHP 36.80',
  ),
];
