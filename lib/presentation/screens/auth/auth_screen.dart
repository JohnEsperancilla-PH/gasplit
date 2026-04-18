import 'package:flutter/material.dart';

import '../../widgets/feature_placeholder_scaffold.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholderScaffold(
      title: 'Auth Screen',
      description: 'Sign in with Google or email/password to continue.',
    );
  }
}
