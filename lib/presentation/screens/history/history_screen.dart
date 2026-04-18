import 'package:flutter/material.dart';

import '../../widgets/feature_placeholder_scaffold.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholderScaffold(
      title: 'History Screen',
      description: 'Completed trips list and filters will appear here.',
    );
  }
}
