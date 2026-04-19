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
  _PassengerFilter _selectedPassengerFilter = _PassengerFilter.all;
  bool _sortNewestFirst = true;

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

  List<TripSummaryData> _filterTrips(List<TripSummaryData> trips) {
    final query = _searchController.text.trim().toLowerCase();
    final filtered =
        trips
            .where((trip) {
              final route = _routeLabel(trip).toLowerCase();
              final date = _formatDateTime(trip.endedAt).toLowerCase();
              final total = _formatPeso(trip.totalCost).toLowerCase();
              final perPerson = _formatPeso(trip.perPersonShare).toLowerCase();
              final passengerText = '${trip.passengerCount} pax';
              final matchesQuery =
                  query.isEmpty ||
                  route.contains(query) ||
                  date.contains(query) ||
                  total.contains(query) ||
                  perPerson.contains(query) ||
                  passengerText.contains(query);

              return matchesQuery && _matchesPassengerFilter(trip);
            })
            .toList(growable: false)
          ..sort((a, b) {
            if (_sortNewestFirst) {
              return b.endedAt.compareTo(a.endedAt);
            }
            return a.endedAt.compareTo(b.endedAt);
          });

    return filtered;
  }

  bool _matchesPassengerFilter(TripSummaryData trip) {
    switch (_selectedPassengerFilter) {
      case _PassengerFilter.all:
        return true;
      case _PassengerFilter.upTo2:
        return trip.passengerCount <= 2;
      case _PassengerFilter.between3And4:
        return trip.passengerCount >= 3 && trip.passengerCount <= 4;
      case _PassengerFilter.atLeast5:
        return trip.passengerCount >= 5;
    }
  }

  @override
  Widget build(BuildContext context) {
    final allTrips = ref.watch(mergedHistoryProvider);
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
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _PassengerFilterChip(
                            label: AppStrings.historyFilterAll,
                            selected:
                                _selectedPassengerFilter ==
                                _PassengerFilter.all,
                            onSelected: () {
                              setState(() {
                                _selectedPassengerFilter = _PassengerFilter.all;
                                _visibleCount = 5;
                              });
                            },
                          ),
                          _PassengerFilterChip(
                            label: AppStrings.historyFilterUpTo2,
                            selected:
                                _selectedPassengerFilter ==
                                _PassengerFilter.upTo2,
                            onSelected: () {
                              setState(() {
                                _selectedPassengerFilter =
                                    _PassengerFilter.upTo2;
                                _visibleCount = 5;
                              });
                            },
                          ),
                          _PassengerFilterChip(
                            label: AppStrings.historyFilter3to4,
                            selected:
                                _selectedPassengerFilter ==
                                _PassengerFilter.between3And4,
                            onSelected: () {
                              setState(() {
                                _selectedPassengerFilter =
                                    _PassengerFilter.between3And4;
                                _visibleCount = 5;
                              });
                            },
                          ),
                          _PassengerFilterChip(
                            label: AppStrings.historyFilter5Plus,
                            selected:
                                _selectedPassengerFilter ==
                                _PassengerFilter.atLeast5,
                            onSelected: () {
                              setState(() {
                                _selectedPassengerFilter =
                                    _PassengerFilter.atLeast5;
                                _visibleCount = 5;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _sortNewestFirst = !_sortNewestFirst;
                        _visibleCount = 5;
                      });
                    },
                    icon: Icon(
                      _sortNewestFirst
                          ? Icons.arrow_downward_rounded
                          : Icons.arrow_upward_rounded,
                    ),
                    tooltip: _sortNewestFirst
                        ? AppStrings.historySortNewestTooltip
                        : AppStrings.historySortOldestTooltip,
                  ),
                ],
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
                                extra: trip,
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
}

enum _PassengerFilter { all, upTo2, between3And4, atLeast5 }

class _PassengerFilterChip extends StatelessWidget {
  const _PassengerFilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
      ),
    );
  }
}

class _HistoryTripTile extends StatelessWidget {
  const _HistoryTripTile({required this.trip, required this.onTap});

  final TripSummaryData trip;
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
              Text(_routeLabel(trip), style: textTheme.titleMedium),
              const SizedBox(height: 2),
              Text(_formatDateTime(trip.endedAt), style: textTheme.bodyMedium),
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
                    '${AppStrings.historyDurationLabel}: ${_formatDuration(trip.duration)}',
                    style: textTheme.bodyLarge,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${AppStrings.historyTotalLabel}: ${_formatPeso(trip.totalCost)}',
                      style: textTheme.bodyLarge,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${AppStrings.historyPerPersonLabel}: ${_formatPeso(trip.perPersonShare)}',
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

String _routeLabel(TripSummaryData trip) {
  if (trip.routeLabel.trim().isEmpty) {
    return AppStrings.tripSummaryRouteFallback;
  }
  return trip.routeLabel;
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
