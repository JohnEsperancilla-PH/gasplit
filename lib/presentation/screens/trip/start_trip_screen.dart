import 'package:flutter/material.dart';

import '../../widgets/feature_placeholder_scaffold.dart';

class StartTripScreen extends StatelessWidget {
  const StartTripScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholderScaffold(
      title: 'Start Trip Screen',
      description: 'Trip setup inputs and map preview will live here.',
    );
  }
}
