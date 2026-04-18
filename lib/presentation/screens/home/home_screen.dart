import 'package:flutter/material.dart';

import '../../widgets/feature_placeholder_scaffold.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholderScaffold(
      title: 'Home Screen',
      description: 'Trip history and quick start action will appear here.',
    );
  }
}
