import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gasplit/app.dart';
import 'package:gasplit/core/constants/app_strings.dart';

void main() {
  testWidgets('shows auth UI content on startup', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: GaSplitApp()));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.appName), findsOneWidget);
    expect(find.text(AppStrings.authGoogleButton), findsOneWidget);
    expect(find.text(AppStrings.authEmailButton), findsOneWidget);
  });

  testWidgets('google button navigates to home placeholder', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: GaSplitApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.authGoogleButton));
    await tester.pumpAndSettle();

    expect(
      find.text('Trip history and quick start action will appear here.'),
      findsOneWidget,
    );
  });
}
