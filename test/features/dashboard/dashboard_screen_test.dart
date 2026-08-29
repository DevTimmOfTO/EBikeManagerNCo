import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:ebikemanager/core/database/app_database.dart';
import 'package:ebikemanager/core/database/repositories/drift_battery_history_repository.dart';
import 'package:ebikemanager/core/database/repositories/drift_bike_repository.dart';
import 'package:ebikemanager/core/database/repositories/drift_trip_repository.dart';
import 'package:ebikemanager/core/domain/entities/battery_history_entry.dart';
import 'package:ebikemanager/core/domain/entities/bike.dart';
import 'package:ebikemanager/core/domain/entities/trip.dart';
import 'package:ebikemanager/core/domain/enums.dart';
import 'package:ebikemanager/features/dashboard/presentation/dashboard_screen.dart';
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

Future<void> _pumpDashboard(
  WidgetTester tester,
  ProviderContainer container,
) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: DashboardScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

Bike _makeBike({
  required String id,
  required String nickname,
  DateTime? purchaseDate,
}) {
  final now = DateTime.now();
  return Bike(
    id: id,
    nickname: nickname,
    createdAt: now,
    updatedAt: now,
    manufacturer: 'Acme',
    model: 'Volt 3',
    purchaseDate: purchaseDate,
  );
}

void main() {
  // Each test intentionally opens its own isolated in-memory database.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets('shows the empty state and its CTA when there are no bikes', (
    tester,
  ) async {
    final container = _buildContainer();
    await _pumpDashboard(tester, container);

    expect(find.text('No bikes yet'), findsOneWidget);
    expect(find.text('Add your first bike'), findsOneWidget);
  });

  testWidgets(
    'shows the bike summary and stats for a single bike, without a selector',
    (
      tester,
    ) async {
      final container = _buildContainer();
      final purchaseDate = DateTime.now().subtract(const Duration(days: 10));
      await container
          .read(bikeRepositoryProvider)
          .saveBike(
            _makeBike(
              id: 'bike-1',
              nickname: 'Blitz',
              purchaseDate: purchaseDate,
            ),
          );

      await _pumpDashboard(tester, container);

      expect(find.text('Blitz'), findsOneWidget);
      expect(find.text('Acme Volt 3'), findsOneWidget);
      // No battery/trip history yet, and no multi-bike selector for one bike.
      expect(find.text('—'), findsNWidgets(2));
      expect(find.text('10 d'), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<String>), findsNothing);
    },
  );

  testWidgets(
    'formats battery health and last-trip stats from the latest records',
    (
      tester,
    ) async {
      final container = _buildContainer();
      await container
          .read(bikeRepositoryProvider)
          .saveBike(_makeBike(id: 'bike-1', nickname: 'Blitz'));

      final now = DateTime.now();
      await container
          .read(batteryHistoryRepositoryProvider)
          .saveEntry(
            BatteryHistoryEntry(
              id: 'entry-1',
              bikeId: 'bike-1',
              timestamp: now,
              eventType: BatteryEventType.healthCheck,
              createdAt: now,
              updatedAt: now,
              estimatedHealthPct: 87.4,
            ),
          );
      await container
          .read(tripRepositoryProvider)
          .saveTrip(
            Trip(
              id: 'trip-1',
              startTime: DateTime(2026, 3, 4),
              source: TripSource.manual,
              createdAt: now,
              updatedAt: now,
              bikeId: 'bike-1',
              distanceMeters: 12500,
            ),
          );

      await _pumpDashboard(tester, container);

      expect(find.text('87%'), findsOneWidget);
      expect(find.text('2026-03-04 · 12.5 km'), findsOneWidget);
    },
  );

  testWidgets('shows a bike selector once a second bike exists', (
    tester,
  ) async {
    final container = _buildContainer();
    await container
        .read(bikeRepositoryProvider)
        .saveBike(_makeBike(id: 'bike-1', nickname: 'Blitz'));
    await container
        .read(bikeRepositoryProvider)
        .saveBike(_makeBike(id: 'bike-2', nickname: 'Sparky'));

    await _pumpDashboard(tester, container);

    expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
  });
}
