import 'package:drift/drift.dart';
import 'package:ebikemanager/core/database/repositories/drift_bike_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'bike_detail_test_helpers.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets('editing an existing bike pre-fills and updates its fields', (
    tester,
  ) async {
    final container = buildBikeTestContainer();
    await container
        .read(bikeRepositoryProvider)
        .saveBike(makeTestBike('bike-1', 'Blitz'));

    await pumpBikeDetail(tester, container, bikeId: 'bike-1');

    expect(find.widgetWithText(AppBar, 'Blitz'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Manufacturer'),
      'Acme',
    );
    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    expect(find.text('Bike saved'), findsOneWidget);
    final saved = await container
        .read(bikeRepositoryProvider)
        .getBikeById('bike-1');
    expect(saved!.manufacturer, 'Acme');
  });
}
