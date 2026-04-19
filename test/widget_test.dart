import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gasplit/app.dart';
import 'package:gasplit/core/constants/app_strings.dart';

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  int maxPumps = 20,
  Duration step = const Duration(milliseconds: 100),
}) async {
  for (var i = 0; i < maxPumps; i++) {
    await tester.pump(step);
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }
}

void main() {
  testWidgets('shows auth UI content on startup', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: GaSplitApp()));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.appName), findsOneWidget);
    expect(find.text(AppStrings.authGoogleButton), findsOneWidget);
    expect(find.text(AppStrings.authEmailButton), findsOneWidget);
  });

  testWidgets('google button navigates to home screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: GaSplitApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.authGoogleButton));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.homeStartTripButton), findsOneWidget);
    expect(find.text(AppStrings.homeHistoryTitle), findsOneWidget);
  });

  testWidgets('home start trip button navigates to start trip screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: GaSplitApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.authGoogleButton));
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.homeStartTripButton));
    await _pumpUntilFound(tester, find.text(AppStrings.startTripTitle));

    expect(find.text(AppStrings.startTripTitle), findsOneWidget);
    expect(find.text(AppStrings.startTripFuelLabel), findsOneWidget);
    expect(find.text(AppStrings.startTripGasPriceLabel), findsOneWidget);
  });

  testWidgets('start trip shows validation when passenger is not selected', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: GaSplitApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.authGoogleButton));
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.homeStartTripButton));
    await _pumpUntilFound(tester, find.text(AppStrings.startTripTitle));

    await tester.tap(find.text(AppStrings.startTripButton));
    await tester.pump();

    expect(find.text(AppStrings.startTripValidationPassengers), findsWidgets);
  });

  testWidgets('start trip navigates to live screen when form is valid', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: GaSplitApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.authGoogleButton));
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.homeStartTripButton));
    await _pumpUntilFound(tester, find.text(AppStrings.startTripTitle));

    await tester.tap(find.text('3'));
    await tester.pump();

    await tester.tap(find.text(AppStrings.startTripButton));
    await _pumpUntilFound(tester, find.text(AppStrings.liveMeterTitle));

    expect(find.text(AppStrings.liveMeterTitle), findsOneWidget);
    expect(find.text(AppStrings.liveMeterEndTripButton), findsOneWidget);
  });

  testWidgets('view all navigates to history screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: GaSplitApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.authGoogleButton));
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.homeHistoryCta));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.historyTitle), findsOneWidget);
    expect(find.text(AppStrings.historySearchHint), findsOneWidget);
  });

  testWidgets('history tile opens trip summary route', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: GaSplitApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.authGoogleButton));
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.homeHistoryCta));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Roxas Ave -> SM City'));
    await tester.pumpAndSettle();

    expect(
      find.text('Summary details for trip ID: trip_20260417_1'),
      findsOneWidget,
    );
  });
}
