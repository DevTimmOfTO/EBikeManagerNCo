import 'package:ebikemanager/features/repair/data/asset_repair_guide_repository.dart';
import 'package:ebikemanager/features/repair/presentation/repair_guide_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_repair_guide_repository.dart';

Future<void> _pumpScreen(WidgetTester tester, String slug) async {
  // The detail screen's content is taller than the default 800x600 test
  // surface, which would leave the step carousel outside the ListView's
  // built cache extent. Use a taller virtual viewport instead of scrolling.
  tester.view.physicalSize = const Size(400, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        repairGuideRepositoryProvider.overrideWith(
          (ref) => FakeRepairGuideRepository(),
        ),
      ],
      child: MaterialApp(home: RepairGuideDetailScreen(slug: slug)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'shows guide content, tools checklist, and steps through the carousel',
    (
      tester,
    ) async {
      await _pumpScreen(tester, 'flat-tire-repair');

      expect(find.text('Flat Tire Repair'), findsOneWidget);
      expect(find.text('Tire levers'), findsOneWidget);
      expect(find.text('1 / 7'), findsOneWidget);
      expect(
        find.textContaining('Shift to the smallest rear cog'),
        findsOneWidget,
      );

      await tester.tap(find.widgetWithText(TextButton, 'Next'));
      await tester.pumpAndSettle();

      expect(find.text('2 / 7'), findsOneWidget);
    },
  );

  testWidgets('shows a not-found message for an unknown slug', (tester) async {
    await _pumpScreen(tester, 'nonexistent');

    expect(find.text('Guide not found.'), findsOneWidget);
  });
}
