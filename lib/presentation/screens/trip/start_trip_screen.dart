import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/models/trip_session_config.dart';

const int _customPassengerOption = -1;

class StartTripScreen extends StatefulWidget {
  const StartTripScreen({super.key});

  @override
  State<StartTripScreen> createState() => _StartTripScreenState();
}

class _StartTripScreenState extends State<StartTripScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _fuelController = TextEditingController(
    text: '12',
  );
  final TextEditingController _gasPriceController = TextEditingController(
    text: '65',
  );
  final TextEditingController _customPassengerController =
      TextEditingController();

  late final AnimationController _pulseController;
  int? _selectedPassengerCount;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fuelController.dispose();
    _gasPriceController.dispose();
    _customPassengerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.startTripTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MapPreviewCard(pulseController: _pulseController),
              const SizedBox(height: 18),
              Text(
                AppStrings.startTripVehicleDetails,
                style: textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _fuelController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: AppStrings.startTripFuelLabel,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _gasPriceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: AppStrings.startTripGasPriceLabel,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                AppStrings.startTripPassengersTitle,
                style: textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final option in _passengerOptions)
                    ChoiceChip(
                      label: Text(option.label),
                      selected: _selectedPassengerCount == option.value,
                      onSelected: (_) {
                        setState(() {
                          _selectedPassengerCount = option.value;
                          if (_selectedPassengerCount !=
                              _customPassengerOption) {
                            _customPassengerController.clear();
                          }
                        });
                      },
                    ),
                ],
              ),
              if (_selectedPassengerCount == _customPassengerOption) ...[
                const SizedBox(height: 10),
                TextField(
                  controller: _customPassengerController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: AppStrings.startTripCustomPassengersLabel,
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _onStartTrip,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    backgroundColor: AppColors.darkSurface,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(AppStrings.startTripButton),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onStartTrip() {
    final fuelEfficiency = double.tryParse(_fuelController.text.trim());
    final gasPrice = double.tryParse(_gasPriceController.text.trim());

    if (fuelEfficiency == null || fuelEfficiency <= 0) {
      _showValidation(AppStrings.startTripValidationFuel);
      return;
    }

    if (gasPrice == null || gasPrice <= 0) {
      _showValidation(AppStrings.startTripValidationGas);
      return;
    }

    if (_selectedPassengerCount == null) {
      _showValidation(AppStrings.startTripValidationPassengers);
      return;
    }

    final resolvedPassengerCount = _resolvePassengerCount();
    if (resolvedPassengerCount == null || resolvedPassengerCount <= 0) {
      _showValidation(AppStrings.startTripValidationCustomPassengers);
      return;
    }

    if (!mounted) {
      return;
    }
    context.go(
      '/trip/live',
      extra: TripSessionConfig(
        fuelEfficiencyKmPerLiter: fuelEfficiency,
        gasPricePerLiter: gasPrice,
        passengerCount: resolvedPassengerCount,
      ),
    );
  }

  int? _resolvePassengerCount() {
    if (_selectedPassengerCount == _customPassengerOption) {
      return int.tryParse(_customPassengerController.text.trim());
    }
    return _selectedPassengerCount;
  }

  void _showValidation(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _MapPreviewCard extends StatelessWidget {
  const _MapPreviewCard({required this.pulseController});

  final AnimationController pulseController;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: SizedBox(
        height: 200,
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.darkSurface,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            Positioned(
              left: 14,
              top: 14,
              child: Text(
                AppStrings.startTripMapTitle,
                style: textTheme.titleMedium?.copyWith(color: Colors.white),
              ),
            ),
            Center(
              child: AnimatedBuilder(
                animation: pulseController,
                builder: (context, child) {
                  final scale = 0.9 + (pulseController.value * 0.2);
                  return Transform.scale(scale: scale, child: child);
                },
                child: const Icon(
                  Icons.location_on_rounded,
                  color: AppColors.primaryAccent,
                  size: 54,
                ),
              ),
            ),
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
              child: Text(
                AppStrings.startTripMapHint,
                style: textTheme.bodyMedium?.copyWith(color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PassengerOption {
  const _PassengerOption({required this.label, required this.value});

  final String label;
  final int value;
}

const List<_PassengerOption> _passengerOptions = <_PassengerOption>[
  _PassengerOption(label: '1', value: 1),
  _PassengerOption(label: '2', value: 2),
  _PassengerOption(label: '3', value: 3),
  _PassengerOption(label: '4', value: 4),
  _PassengerOption(label: '5+', value: _customPassengerOption),
];
