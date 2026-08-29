import 'package:ebikemanager/features/repair/data/asset_repair_guide_repository.dart';
import 'package:ebikemanager/features/repair/presentation/repair_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_repair_guide_repository.dart';

Future<void> _pumpScreen(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        repairGuideRepositoryProvider.overrideWith(
          (ref) => FakeRepairGuideRepository(),
        ),
      ],
      child: const MaterialApp(home: RepairListScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('lists all bundled guides by default', (tester) async {
    await _pumpScreen(tester);

    expect(find.text('Flat Tire Repair'), findsOneWidget);
    expect(find.text('Basic Battery Care'), findsOneWidget);
  });

  testWidgets('search narrows the list down to matching guides', (
    tester,
  ) async {
    await _pumpScreen(tester);

    await tester.enterText(find.byType(TextField), 'battery');
    await tester.pumpAndSettle();

    expect(find.text('Basic Battery Care'), findsOneWidget);
    expect(find.text('Flat Tire Repair'), findsNothing);
  });

  testWidgets(
    'selecting a category chip narrows the list, tapping again clears it',
    (
      tester,
    ) async {
      await _pumpScreen(tester);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Tires'));
      await tester.pumpAndSettle();

      expect(find.text('Flat Tire Repair'), findsOneWidget);
      expect(find.text('Tire Pressure Check'), findsOneWidget);
      expect(find.text('Basic Battery Care'), findsNothing);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Tires'));
      await tester.pumpAndSettle();

      expect(find.text('Basic Battery Care'), findsOneWidget);
    },
  );
}
