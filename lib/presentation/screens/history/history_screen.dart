import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final List<_HistoryTrip> _trips;

  int _visibleCount = 5;

  @override
  void initState() {
    super.initState();
    _trips = List<_HistoryTrip>.from(_seedTrips)
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<_HistoryTrip> get _filteredTrips {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return _trips;
    }

    return _trips.where((trip) {
      final route = trip.route.toLowerCase();
      final date = _formatDateTime(trip.dateTime).toLowerCase();
      return route.contains(query) || date.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredTrips = _filteredTrips;
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
                              onTap: () =>
                                  context.go('/trip/summary/${trip.tripId}'),
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
    final filteredCount = _filteredTrips.length;
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
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) {
      return;
    }
    setState(() {
      _trips.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      _visibleCount = 5;
    });
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
  });

  final String tripId;
  final String route;
  final DateTime dateTime;
  final int passengerCount;
  final double distanceKm;
  final String durationText;
  final String totalCostText;
  final String perPersonText;
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
