import 'package:drift/drift.dart';
import 'package:ebikemanager/core/database/repositories/drift_bike_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'bike_detail_test_helpers.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets('archiving a bike via the menu toggles isArchived', (
    tester,
  ) async {
    final container = buildBikeTestContainer();
    await container
        .read(bikeRepositoryProvider)
        .saveBike(makeTestBike('bike-1', 'Blitz'));

    await pumpBikeDetail(tester, container, bikeId: 'bike-1');
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Archive'));
    await tester.pumpAndSettle();

    final saved = await container
        .read(bikeRepositoryProvider)
        .getBikeById('bike-1');
    expect(saved!.isArchived, isTrue);
  });
}
