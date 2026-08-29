import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:ebikemanager/core/database/app_database.dart';
import 'package:ebikemanager/core/database/repositories/drift_bike_repository.dart';
import 'package:ebikemanager/core/domain/entities/bike.dart';
import 'package:ebikemanager/features/profile/presentation/manage_bikes_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

ProviderContainer _buildContainer() {
  final container = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWith(
        (ref) => AppDatabase(NativeDatabase.memory()),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

Future<void> _pumpScreen(
  WidgetTester tester,
  ProviderContainer container,
) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: ManageBikesScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

Bike _bike(String id, String nickname, {bool isArchived = false}) {
  final now = DateTime.now();
  return Bike(
    id: id,
    nickname: nickname,
    createdAt: now,
    updatedAt: now,
    isArchived: isArchived,
  );
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets('shows an empty state when there are no bikes', (tester) async {
    final container = _buildContainer();
    await _pumpScreen(tester, container);

    expect(find.text('No bikes yet.'), findsOneWidget);
  });

  testWidgets('lists both active and archived bikes, tagging archived ones', (
    tester,
  ) async {
    final container = _buildContainer();
    await container
        .read(bikeRepositoryProvider)
        .saveBike(_bike('bike-1', 'Blitz'));
    await container
        .read(bikeRepositoryProvider)
        .saveBike(_bike('bike-2', 'Retired', isArchived: true));

    await _pumpScreen(tester, container);

    expect(find.text('Blitz'), findsOneWidget);
    expect(find.text('Retired'), findsOneWidget);
    expect(find.text('Archived'), findsOneWidget);
  });

  testWidgets('the FAB is present to add a new bike', (tester) async {
    final container = _buildContainer();
    await _pumpScreen(tester, container);

    expect(
      find.widgetWithText(FloatingActionButton, 'Add bike'),
      findsOneWidget,
    );
  });
}
