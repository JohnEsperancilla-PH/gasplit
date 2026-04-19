import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/models/trip_summary_data.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/history_provider.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isAuthenticating = false;
  bool _didNavigateHome = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final textTheme = Theme.of(context).textTheme;
    final recentTrips = _buildRecentTrips(ref.watch(recentTripsProvider));
    final signedInUser = authState.valueOrNull;
    final isBusy = _isAuthenticating || authState.isLoading;

    if (signedInUser != null && !_didNavigateHome) {
      _didNavigateHome = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        context.go('/home');
      });
    }

    if (signedInUser == null) {
      _didNavigateHome = false;
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              const _BrandMark(),
              const SizedBox(height: 18),
              Text(
                AppStrings.appName,
                textAlign: TextAlign.center,
                style: textTheme.titleLarge?.copyWith(
                  fontSize: 34,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.tagline,
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge,
              ),
              const SizedBox(height: 28),
              Text(
                AppStrings.authTitle,
                style: textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              if (authState.isLoading && signedInUser == null) ...[
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    Text(AppStrings.authCheckingSessionLabel),
                  ],
                ),
              ],
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: isBusy ? null : _onGoogleSignIn,
                icon: const Icon(Icons.g_mobiledata_rounded, size: 24),
                label: const Text(AppStrings.authGoogleButton),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  backgroundColor: AppColors.primaryAccent,
                  foregroundColor: AppColors.darkSurface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: isBusy ? null : _onEmailAuth,
                icon: const Icon(Icons.email_outlined),
                label: const Text(AppStrings.authEmailButton),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.border, width: 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppStrings.authRecentTripsTitle,
                    style: textTheme.titleMedium,
                  ),
                  Text(
                    AppStrings.authRecentTripsSubtitle,
                    style: textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...recentTrips.map(_RecentTripTile.new),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onGoogleSignIn() async {
    setState(() {
      _isAuthenticating = true;
    });

    try {
      final user = await ref.read(authControllerProvider).signInWithGoogle();
      if (user == null && mounted) {
        _showSnack(AppStrings.authGoogleCancelledSnack);
      }
    } catch (error) {
      if (mounted) {
        _showSnack(
          '${AppStrings.authSignInFailedPrefix}: ${_errorMessage(error)}',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
        });
      }
    }
  }

  Future<void> _onEmailAuth() async {
    final request = await showModalBottomSheet<_EmailAuthRequest>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const _EmailAuthSheet(),
    );

    if (request == null) {
      return;
    }

    setState(() {
      _isAuthenticating = true;
    });

    try {
      if (request.createAccount) {
        await ref
            .read(authControllerProvider)
            .createAccountWithEmailPassword(
              email: request.email,
              password: request.password,
            );
      } else {
        await ref
            .read(authControllerProvider)
            .signInWithEmailPassword(
              email: request.email,
              password: request.password,
            );
      }
    } catch (error) {
      if (mounted) {
        _showSnack(
          '${AppStrings.authSignInFailedPrefix}: ${_errorMessage(error)}',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
        });
      }
    }
  }

  String _errorMessage(Object error) {
    if (error is FirebaseAuthException) {
      return error.message ?? error.code;
    }

    final raw = error.toString();
    if (raw.startsWith('Exception: ')) {
      return raw.substring('Exception: '.length);
    }
    return raw;
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _EmailAuthRequest {
  const _EmailAuthRequest({
    required this.email,
    required this.password,
    required this.createAccount,
  });

  final String email;
  final String password;
  final bool createAccount;
}

class _EmailAuthSheet extends StatefulWidget {
  const _EmailAuthSheet();

  @override
  State<_EmailAuthSheet> createState() => _EmailAuthSheetState();
}

class _EmailAuthSheetState extends State<_EmailAuthSheet> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 8,
        bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppStrings.authEmailDialogTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: AppStrings.authEmailFieldLabel,
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final email = value?.trim() ?? '';
                if (email.isEmpty || !email.contains('@')) {
                  return AppStrings.authValidationEmail;
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: AppStrings.authPasswordFieldLabel,
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final password = value?.trim() ?? '';
                if (password.length < 6) {
                  return AppStrings.authValidationPassword;
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(AppStrings.commonCancel),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _submit(createAccount: false),
                    child: const Text(AppStrings.authSignInAction),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _submit(createAccount: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryAccent,
                foregroundColor: AppColors.darkSurface,
              ),
              child: const Text(AppStrings.authCreateAccountAction),
            ),
          ],
        ),
      ),
    );
  }

  void _submit({required bool createAccount}) {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    Navigator.of(context).pop(
      _EmailAuthRequest(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        createAccount: createAccount,
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 78,
        height: 78,
        decoration: const BoxDecoration(
          color: AppColors.primaryAccent,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.local_gas_station_rounded,
          size: 34,
          color: AppColors.darkSurface,
        ),
      ),
    );
  }
}

class _RecentTripInfo {
  const _RecentTripInfo({
    required this.route,
    required this.meta,
    required this.share,
  });

  final String route;
  final String meta;
  final String share;
}

class _RecentTripTile extends StatelessWidget {
  const _RecentTripTile(this.trip);

  final _RecentTripInfo trip;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(trip.route, style: textTheme.titleMedium),
                  const SizedBox(height: 3),
                  Text(trip.meta, style: textTheme.bodyMedium),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              trip.share,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

List<_RecentTripInfo> _buildRecentTrips(List<TripSummaryData> recentTrips) {
  return recentTrips.map(_recentTripFromSummary).toList(growable: false);
}

_RecentTripInfo _recentTripFromSummary(TripSummaryData summary) {
  final routeLabel = summary.routeLabel.trim().isEmpty
      ? AppStrings.tripSummaryRouteFallback
      : summary.routeLabel;

  return _RecentTripInfo(
    route: routeLabel,
    meta:
        '${_formatDateTime(summary.endedAt)} - ${summary.passengerCount} pax - ${summary.distanceKm.toStringAsFixed(1)} km',
    share: _formatPeso(summary.perPersonShare),
  );
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

String _formatPeso(double amount) {
  return 'PHP ${amount.toStringAsFixed(2)}';
}
