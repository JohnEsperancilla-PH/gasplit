import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/models/trip_summary_data.dart';
import '../../../providers/history_provider.dart';

class TripSummaryScreen extends ConsumerStatefulWidget {
  const TripSummaryScreen({required this.tripId, this.initialData, super.key});

  final String tripId;
  final TripSummaryData? initialData;

  @override
  ConsumerState<TripSummaryScreen> createState() => _TripSummaryScreenState();
}

class _TripSummaryScreenState extends ConsumerState<TripSummaryScreen> {
  late final TripSummaryData _summary;
  bool _savedToHistory = false;

  @override
  void initState() {
    super.initState();
    _summary = widget.initialData ?? _seedSummaryByTripId(widget.tripId);
  }

  @override
  Widget build(BuildContext context) {
    final hasSavedRecord = ref
        .watch(historyProvider)
        .any((trip) => trip.tripId == _summary.tripId);
    final isSaved = _savedToHistory || hasSavedRecord;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.tripSummaryTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SummaryHeroCard(summary: _summary),
              const SizedBox(height: 12),
              _TripDetailsCard(summary: _summary),
              const SizedBox(height: 12),
              _PassengerBreakdownCard(summary: _summary),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _onShareBreakdown,
                icon: const Icon(Icons.share_outlined),
                label: const Text(AppStrings.tripSummaryShareButton),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  backgroundColor: AppColors.primaryAccent,
                  foregroundColor: AppColors.darkSurface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: isSaved ? null : _onSaveToHistory,
                icon: Icon(
                  isSaved
                      ? Icons.check_circle_rounded
                      : Icons.bookmark_add_outlined,
                ),
                label: Text(
                  isSaved
                      ? AppStrings.tripSummarySavedButton
                      : AppStrings.tripSummarySaveButton,
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  side: const BorderSide(color: AppColors.border, width: 1),
                  foregroundColor: AppColors.textPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onShareBreakdown() async {
    final shareText = _buildShareText(_summary);

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.tripSummarySharePreviewTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: SelectableText(shareText),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(AppStrings.commonClose),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: shareText),
                          );
                          if (!context.mounted) {
                            return;
                          }
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(this.context)
                            ..clearSnackBars()
                            ..showSnackBar(
                              const SnackBar(
                                content: Text(
                                  AppStrings.tripSummaryCopiedSnack,
                                ),
                              ),
                            );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryAccent,
                          foregroundColor: AppColors.darkSurface,
                        ),
                        child: const Text(AppStrings.tripSummaryCopyButton),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _onSaveToHistory() async {
    if (_savedToHistory) {
      return;
    }

    await ref.read(historyProvider.notifier).saveTrip(_summary);

    if (!mounted) {
      return;
    }

    setState(() {
      _savedToHistory = true;
    });

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        const SnackBar(content: Text(AppStrings.tripSummarySavedSnack)),
      );
  }
}

class _SummaryHeroCard extends StatelessWidget {
  const _SummaryHeroCard({required this.summary});

  final TripSummaryData summary;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.success,
            child: Icon(Icons.check_rounded, color: Colors.white),
          ),
          const SizedBox(height: 10),
          Text(
            AppStrings.tripSummaryCompletedLabel,
            style: textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 4),
          Text(
            _formatPeso(summary.totalCost),
            style: textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _formatDateTime(summary.endedAt),
            style: textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 2),
          Text(
            summary.routeLabel,
            style: textTheme.bodyLarge?.copyWith(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _TripDetailsCard extends StatelessWidget {
  const _TripDetailsCard({required this.summary});

  final TripSummaryData summary;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.tripSummaryDetailsTitle,
              style: textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            _DetailRow(
              label: AppStrings.tripSummaryDistanceLabel,
              value: '${summary.distanceKm.toStringAsFixed(1)} km',
            ),
            _DetailRow(
              label: AppStrings.tripSummaryDurationLabel,
              value: _formatDuration(summary.duration),
            ),
            _DetailRow(
              label: AppStrings.tripSummaryGasUsedLabel,
              value: '${summary.gasUsedLiters.toStringAsFixed(2)} L',
            ),
            _DetailRow(
              label: AppStrings.tripSummaryFuelReferenceLabel,
              value:
                  '${summary.fuelEfficiencyKmPerLiter.toStringAsFixed(1)} km/L @ ${_formatPeso(summary.gasPricePerLiter)}/L',
            ),
          ],
        ),
      ),
    );
  }
}

class _PassengerBreakdownCard extends StatelessWidget {
  const _PassengerBreakdownCard({required this.summary});

  final TripSummaryData summary;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    AppStrings.tripSummaryPassengerBreakdownTitle,
                    style: textTheme.titleMedium,
                  ),
                ),
                Text(
                  '${summary.passengerCount} ${AppStrings.liveMeterPassengersSuffix}',
                  style: textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 10),
            for (var i = 0; i < summary.passengerCount; i++)
              _PassengerShareRow(
                index: i,
                passengerName: i == 0
                    ? AppStrings.liveMeterDriverLabel
                    : '${AppStrings.liveMeterPassengerLabel} ${i + 1}',
                shareText: _formatPeso(summary.perPersonShare),
              ),
          ],
        ),
      ),
    );
  }
}

class _PassengerShareRow extends StatelessWidget {
  const _PassengerShareRow({
    required this.index,
    required this.passengerName,
    required this.shareText,
  });

  final int index;
  final String passengerName;
  final String shareText;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final avatarColor = _avatarColors[index % _avatarColors.length];
    final initials = index == 0 ? 'YU' : 'P${index + 1}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: avatarColor,
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(passengerName, style: textTheme.bodyLarge)),
          Text(
            shareText,
            style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: textTheme.bodyLarge)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

TripSummaryData _seedSummaryByTripId(String tripId) {
  switch (tripId) {
    case 'trip_20260417_1':
      return _buildSeedSummary(
        tripId: tripId,
        routeLabel: 'Roxas Ave -> SM City',
        endedAt: DateTime(2026, 4, 17, 18, 12),
        durationMinutes: 12,
        distanceKm: 6.2,
        totalCost: 73.8,
        passengerCount: 3,
        perPersonShare: 24.6,
      );
    case 'trip_20260416_1':
      return _buildSeedSummary(
        tripId: tripId,
        routeLabel: 'Bajada -> Matina',
        endedAt: DateTime(2026, 4, 16, 8, 5),
        durationMinutes: 20,
        distanceKm: 8.4,
        totalCost: 108.6,
        passengerCount: 4,
        perPersonShare: 27.15,
      );
    case 'trip_20260415_1':
      return _buildSeedSummary(
        tripId: tripId,
        routeLabel: 'Lanang -> Abreeza',
        endedAt: DateTime(2026, 4, 15, 7, 38),
        durationMinutes: 9,
        distanceKm: 4.1,
        totalCost: 38.8,
        passengerCount: 2,
        perPersonShare: 19.4,
      );
    default:
      final endedAt = DateTime.now();
      return _buildSeedSummary(
        tripId: tripId,
        routeLabel: AppStrings.tripSummaryRouteFallback,
        endedAt: endedAt,
        durationMinutes: 10,
        distanceKm: 5.0,
        totalCost: 54.2,
        passengerCount: 3,
        perPersonShare: 18.07,
      );
  }
}

TripSummaryData _buildSeedSummary({
  required String tripId,
  required String routeLabel,
  required DateTime endedAt,
  required int durationMinutes,
  required double distanceKm,
  required double totalCost,
  required int passengerCount,
  required double perPersonShare,
}) {
  const fuelEfficiencyKmPerLiter = 12.0;
  const gasPricePerLiter = 65.0;
  final duration = Duration(minutes: durationMinutes);

  return TripSummaryData(
    tripId: tripId,
    routeLabel: routeLabel,
    startedAt: endedAt.subtract(duration),
    endedAt: endedAt,
    distanceKm: distanceKm,
    duration: duration,
    fuelEfficiencyKmPerLiter: fuelEfficiencyKmPerLiter,
    gasPricePerLiter: gasPricePerLiter,
    gasUsedLiters: totalCost / gasPricePerLiter,
    totalCost: totalCost,
    passengerCount: passengerCount,
    perPersonShare: perPersonShare,
  );
}

String _formatPeso(double amount) {
  return 'PHP ${amount.toStringAsFixed(2)}';
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

String _buildShareText(TripSummaryData summary) {
  final routeLabel = summary.routeLabel.trim().isEmpty
      ? AppStrings.tripSummaryRouteFallback
      : summary.routeLabel;

  return [
    'GaSplit Trip Summary',
    _formatDateTime(summary.endedAt),
    routeLabel,
    '${summary.distanceKm.toStringAsFixed(1)} km - ${_formatDuration(summary.duration)}',
    '',
    'Total gas cost: ${_formatPeso(summary.totalCost)}',
    'Per person (${summary.passengerCount} pax): ${_formatPeso(summary.perPersonShare)}',
    '',
    AppStrings.tripSummaryPoweredBy,
  ].join('\n');
}

const List<Color> _avatarColors = <Color>[
  AppColors.success,
  Color(0xFF1E88E5),
  Color(0xFFF57C00),
  Color(0xFF5E35B1),
  Color(0xFF546E7A),
];
