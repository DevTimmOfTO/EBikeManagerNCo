import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:ebikemanager/core/database/app_database.dart';
import 'package:ebikemanager/core/database/repositories/drift_bike_repository.dart';
import 'package:ebikemanager/core/database/repositories/drift_trip_repository.dart';
import 'package:ebikemanager/core/domain/entities/bike.dart';
import 'package:ebikemanager/core/domain/entities/trip.dart';
import 'package:ebikemanager/core/domain/enums.dart';
import 'package:ebikemanager/features/history/presentation/history_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

ProviderContainer _buildContainer() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
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
      child: const MaterialApp(home: HistoryScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

Bike _makeBike(String id, String nickname) {
  final now = DateTime.now();
  return Bike(id: id, nickname: nickname, createdAt: now, updatedAt: now);
}

Trip _makeTrip(
  String id,
  String bikeId,
  DateTime startTime, {
  double? distanceMeters,
}) {
  final now = DateTime.now();
  return Trip(
    id: id,
    startTime: startTime,
    source: TripSource.manual,
    createdAt: now,
    updatedAt: now,
    bikeId: bikeId,
    distanceMeters: distanceMeters,
  );
}

void main() {
  testWidgets('shows a prompt to add a bike first when there are none', (
    tester,
  ) async {
    final container = _buildContainer();
    await _pumpScreen(tester, container);

    expect(find.text('Add a bike first to see its history.'), findsOneWidget);
  });

  testWidgets('trips tab lists trips grouped under a month header', (
    tester,
  ) async {
    final container = _buildContainer();
    await container
        .read(bikeRepositoryProvider)
        .saveBike(_makeBike('bike-1', 'Blitz'));
    await container
        .read(tripRepositoryProvider)
        .saveTrip(
          _makeTrip(
            'trip-1',
            'bike-1',
            DateTime(2026, 3, 4),
            distanceMeters: 5000,
          ),
        );

    await _pumpScreen(tester, container);

    expect(find.text('March 2026'), findsOneWidget);
    expect(find.textContaining('5.0 km'), findsOneWidget);
  });

  testWidgets('battery tab: logging a charge adds a new charge-log entry', (
    tester,
  ) async {
    final container = _buildContainer();
    await container
        .read(bikeRepositoryProvider)
        .saveBike(_makeBike('bike-1', 'Blitz'));
    await _pumpScreen(tester, container);

    // Switch to the Battery tab.
    await tester.tap(find.widgetWithText(Tab, 'Battery'));
    await tester.pumpAndSettle();

    expect(find.text('No charge history yet.'), findsOneWidget);

    await tester.tap(find.widgetWithText(FloatingActionButton, 'Log a charge'));
    await tester.pumpAndSettle();

    expect(find.text('Log a charge'), findsWidgets);
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(find.text('No charge history yet.'), findsNothing);
    expect(find.byType(ListTile), findsWidgets);
  });
}
