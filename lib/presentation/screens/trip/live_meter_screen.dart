import 'package:flutter/material.dart';

import '../../widgets/feature_placeholder_scaffold.dart';

class LiveMeterScreen extends StatelessWidget {
  const LiveMeterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholderScaffold(
      title: 'Live Meter Screen',
      description: 'Live distance, speed, duration, and cost will appear here.',
    );
  }
}
