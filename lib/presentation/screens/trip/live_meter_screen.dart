import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/models/trip_session_config.dart';

class LiveMeterScreen extends StatefulWidget {
  const LiveMeterScreen({required this.config, super.key});

  final TripSessionConfig config;

  @override
  State<LiveMeterScreen> createState() => _LiveMeterScreenState();
}

class _LiveMeterScreenState extends State<LiveMeterScreen>
    with SingleTickerProviderStateMixin {
  final Stopwatch _tripStopwatch = Stopwatch();
  final Random _random = Random();

  late final AnimationController _pulseController;
  Timer? _tickTimer;
  late final DateTime _startedAt;

  double _distanceKm = 0;
  double _speedKmh = 0;

  double get _gasUsedLiters {
    final fuelEfficiency = widget.config.fuelEfficiencyKmPerLiter;
    if (fuelEfficiency <= 0) {
      return 0;
    }
    return _distanceKm / fuelEfficiency;
  }

  double get _totalCost => _gasUsedLiters * widget.config.gasPricePerLiter;

  double get _perPersonShare {
    if (widget.config.passengerCount <= 0) {
      return 0;
    }
    return _totalCost / widget.config.passengerCount;
  }

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
    _tripStopwatch.start();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _tickTimer = Timer.periodic(const Duration(seconds: 1), _onTick);
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    _tripStopwatch.stop();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.liveMeterTitle),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    _MapAreaCard(pulseController: _pulseController),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _LiveBadge(pulseController: _pulseController),
                        const Spacer(),
                        Text(
                          '${AppStrings.liveMeterStartedLabel}: ${_formatStartedTime(_startedAt)}',
                          style: textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _formatPeso(_totalCost),
                      style: textTheme.titleLarge?.copyWith(
                        fontSize: 38,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: _showFormulaBottomSheet,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          '${AppStrings.liveMeterTotalCostLabel} - ${AppStrings.liveMeterFormulaHint}',
                          style: textTheme.bodyMedium?.copyWith(
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            label: AppStrings.liveMeterDistanceLabel,
                            value: '${_distanceKm.toStringAsFixed(2)} km',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _StatCard(
                            label: AppStrings.liveMeterSpeedLabel,
                            value: '${_speedKmh.toStringAsFixed(1)} km/h',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _StatCard(
                            label: AppStrings.liveMeterDurationLabel,
                            value: _formatDuration(_tripStopwatch.elapsed),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _PassengerSplitCard(
                      passengerCount: widget.config.passengerCount,
                      perPersonShareText: _formatPeso(_perPersonShare),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _onEndTripPressed,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    backgroundColor: AppColors.danger,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(AppStrings.liveMeterEndTripButton),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onTick(Timer timer) {
    if (!mounted) {
      return;
    }

    final distanceIncrementKm = 0.0035 + (_random.nextDouble() * 0.0065);
    final speed = (distanceIncrementKm * 3600).clamp(0.0, 120.0).toDouble();

    setState(() {
      _distanceKm += distanceIncrementKm;
      _speedKmh = speed;
    });
  }

  Future<void> _onEndTripPressed() async {
    final shouldEnd = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(AppStrings.liveMeterEndDialogTitle),
          content: const Text(AppStrings.liveMeterEndDialogMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(AppStrings.commonCancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
              ),
              child: const Text(AppStrings.liveMeterEndTripButton),
            ),
          ],
        );
      },
    );

    if (shouldEnd != true || !mounted) {
      return;
    }

    final tripId = 'trip_${DateTime.now().millisecondsSinceEpoch}';
    context.go('/trip/summary/$tripId');
  }

  void _showFormulaBottomSheet() {
    showModalBottomSheet<void>(
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
                  AppStrings.liveMeterFormulaTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                _FormulaRow(
                  label: AppStrings.liveMeterFormulaGasUsed,
                  value: '${_gasUsedLiters.toStringAsFixed(2)} L',
                ),
                _FormulaRow(
                  label: AppStrings.liveMeterFormulaFuel,
                  value:
                      '${widget.config.fuelEfficiencyKmPerLiter.toStringAsFixed(1)} km/L',
                ),
                _FormulaRow(
                  label: AppStrings.liveMeterFormulaGasPrice,
                  value:
                      'PHP ${widget.config.gasPricePerLiter.toStringAsFixed(2)} /L',
                ),
                _FormulaRow(
                  label: AppStrings.liveMeterFormulaPassengerCount,
                  value: '${widget.config.passengerCount}',
                ),
                const Divider(height: 24),
                _FormulaRow(
                  label: AppStrings.liveMeterFormulaTotal,
                  value: _formatPeso(_totalCost),
                  emphasize: true,
                ),
                _FormulaRow(
                  label: AppStrings.liveMeterFormulaPerPerson,
                  value: _formatPeso(_perPersonShare),
                  emphasize: true,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatPeso(double amount) {
    return 'PHP ${amount.toStringAsFixed(2)}';
  }

  String _formatDuration(Duration value) {
    final hours = value.inHours;
    final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');

    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '${value.inMinutes.toString().padLeft(2, '0')}:$seconds';
  }

  String _formatStartedTime(DateTime value) {
    final hour24 = value.hour;
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final period = hour24 >= 12 ? 'PM' : 'AM';
    return '$hour12:$minute $period';
  }
}

class _MapAreaCard extends StatelessWidget {
  const _MapAreaCard({required this.pulseController});

  final AnimationController pulseController;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SizedBox(
        height: 220,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              const DecoratedBox(
                decoration: BoxDecoration(color: AppColors.darkSurface),
                child: SizedBox.expand(),
              ),
              const Positioned.fill(
                child: CustomPaint(painter: _RoutePainter()),
              ),
              Positioned(
                left: 12,
                top: 12,
                child: Text(
                  AppStrings.liveMeterMapHint,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                ),
              ),
              const Positioned(
                left: 36,
                bottom: 36,
                child: _MapMarker(color: AppColors.success, label: 'Start'),
              ),
              Positioned(
                right: 46,
                top: 72,
                child: AnimatedBuilder(
                  animation: pulseController,
                  builder: (context, child) {
                    final scale = 0.9 + (pulseController.value * 0.2);
                    return Transform.scale(scale: scale, child: child);
                  },
                  child: const _MapMarker(
                    color: AppColors.primaryAccent,
                    label: 'Now',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapMarker extends StatelessWidget {
  const _MapMarker({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: const Icon(Icons.navigation_rounded, color: Colors.black87),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _RoutePainter extends CustomPainter {
  const _RoutePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..strokeWidth = 1;

    for (var i = 1; i < 6; i++) {
      final dy = size.height * (i / 6);
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), gridPaint);
    }

    final routePath = Path()
      ..moveTo(size.width * 0.2, size.height * 0.75)
      ..quadraticBezierTo(
        size.width * 0.36,
        size.height * 0.58,
        size.width * 0.48,
        size.height * 0.6,
      )
      ..quadraticBezierTo(
        size.width * 0.66,
        size.height * 0.64,
        size.width * 0.82,
        size.height * 0.34,
      );

    final routePaint = Paint()
      ..color = AppColors.primaryAccent.withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(routePath, routePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge({required this.pulseController});

  final AnimationController pulseController;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryAccent.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: pulseController,
            builder: (context, child) {
              final scale = 0.85 + (pulseController.value * 0.3);
              return Transform.scale(scale: scale, child: child);
            },
            child: const DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.primaryAccent,
                shape: BoxShape.circle,
              ),
              child: SizedBox(width: 10, height: 10),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            AppStrings.liveMeterLiveLabel,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: textTheme.bodyMedium),
            const SizedBox(height: 4),
            Text(
              value,
              style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

class _PassengerSplitCard extends StatelessWidget {
  const _PassengerSplitCard({
    required this.passengerCount,
    required this.perPersonShareText,
  });

  final int passengerCount;
  final String perPersonShareText;

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
                    AppStrings.liveMeterPerPersonTitle,
                    style: textTheme.titleMedium,
                  ),
                ),
                Text(
                  '$passengerCount ${AppStrings.liveMeterPassengersSuffix}',
                  style: textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 10),
            for (var i = 0; i < passengerCount; i++)
              _PassengerShareRow(
                index: i,
                passengerName: i == 0
                    ? AppStrings.liveMeterDriverLabel
                    : '${AppStrings.liveMeterPassengerLabel} ${i + 1}',
                shareText: perPersonShareText,
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

class _FormulaRow extends StatelessWidget {
  const _FormulaRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: emphasize
                  ? textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)
                  : textTheme.bodyLarge,
            ),
          ),
          Text(
            value,
            style: emphasize
                ? textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)
                : textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

const List<Color> _avatarColors = <Color>[
  AppColors.success,
  Color(0xFF1E88E5),
  Color(0xFFF57C00),
  Color(0xFF5E35B1),
  Color(0xFF546E7A),
];
