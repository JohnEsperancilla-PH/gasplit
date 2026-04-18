import 'package:flutter/material.dart';

import '../../widgets/feature_placeholder_scaffold.dart';

class TripSummaryScreen extends StatelessWidget {
  const TripSummaryScreen({required this.tripId, super.key});

  final String tripId;

  @override
  Widget build(BuildContext context) {
    return FeaturePlaceholderScaffold(
      title: 'Trip Summary Screen',
      description: 'Summary details for trip ID: $tripId',
    );
  }
}
