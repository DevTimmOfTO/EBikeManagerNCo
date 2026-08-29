import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:ebikemanager/core/database/app_database.dart';
import 'package:ebikemanager/core/database/repositories/drift_bike_repository.dart';
import 'package:ebikemanager/core/database/repositories/drift_trip_repository.dart';
import 'package:ebikemanager/core/domain/entities/bike.dart';
import 'package:ebikemanager/core/domain/entities/trip.dart';
import 'package:ebikemanager/core/domain/enums.dart';
import 'package:ebikemanager/core/health/health_connect_repository.dart';
import 'package:ebikemanager/core/health/health_repository.dart';
import 'package:ebikemanager/features/history/domain/history_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeHealthRepository implements HealthRepository {
  _FakeHealthRepository({
    this.available = true,
    this.permissionsGranted = true,
    this.tripsToReturn = const [],
  });

  final bool available;
  final bool permissionsGranted;
  final List<Trip> tripsToReturn;
  int installPromptCount = 0;

  @override
  Future<bool> isHealthConnectAvailable() async => available;

  @override
  Future<void> promptInstallHealthConnect() async => installPromptCount++;

  @override
  Future<bool> hasPermissions() async => permissionsGranted;

  @override
  Future<bool> requestAuthorization() async => permissionsGranted;

  @override
  Future<List<Trip>> fetchCyclingTrips({
    required DateTime start,
    required DateTime end,
  }) async => tripsToReturn;
}

Future<void> _seedBike(ProviderContainer container, String id) async {
  final now = DateTime.now();
  await container
      .read(bikeRepositoryProvider)
      .saveBike(
        Bike(id: id, nickname: 'Test bike', createdAt: now, updatedAt: now),
      );
}

Trip _healthTrip(String recordId, {String id = 'trip-1'}) {
  final now = DateTime.now();
  return Trip(
    id: id,
    startTime: now,
    source: TripSource.healthConnect,
    createdAt: now,
    updatedAt: now,
    healthConnectRecordId: recordId,
  );
}

void main() {
  // Each test intentionally opens its own isolated in-memory database.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late ProviderContainer container;

  ProviderContainer buildContainer(HealthRepository healthRepository) {
    final c = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith(
          (ref) => AppDatabase(NativeDatabase.memory()),
        ),
        healthRepositoryProvider.overrideWith((ref) => healthRepository),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  test(
    'imports fetched trips not already present, attaching the given bikeId',
    () async {
      container = buildContainer(
        _FakeHealthRepository(
          tripsToReturn: [
            _healthTrip('hc-1'),
            _healthTrip('hc-2', id: 'trip-2'),
          ],
        ),
      );
      await _seedBike(container, 'bike-1');

      await container
          .read(healthSyncControllerProvider.notifier)
          .sync(
            bikeId: 'bike-1',
            start: DateTime(2026),
            end: DateTime(2026, 2),
          );

      final result = container.read(healthSyncControllerProvider);
      expect(result, isA<AsyncData<int>>());
      expect((result! as AsyncData<int>).value, 2);

      final saved = await container
          .read(tripRepositoryProvider)
          .watchAllTrips()
          .first;
      expect(saved, hasLength(2));
      expect(saved.every((t) => t.bikeId == 'bike-1'), isTrue);
    },
  );

  test(
    'skips a trip whose healthConnectRecordId was already imported',
    () async {
      container = buildContainer(
        _FakeHealthRepository(tripsToReturn: [_healthTrip('hc-dup')]),
      );
      await _seedBike(container, 'bike-1');

      final tripRepo = container.read(tripRepositoryProvider);
      // Pre-seed as if this session was already synced once before.
      await tripRepo.saveTrip(_healthTrip('hc-dup', id: 'existing'));

      await container
          .read(healthSyncControllerProvider.notifier)
          .sync(
            bikeId: 'bike-1',
            start: DateTime(2026),
            end: DateTime(2026, 2),
          );

      final result = container.read(healthSyncControllerProvider);
      expect((result! as AsyncData<int>).value, 0);

      final saved = await tripRepo.watchAllTrips().first;
      expect(saved, hasLength(1));
    },
  );

  test(
    'surfaces a HealthConnectNotInstalledException when unavailable',
    () async {
      container = buildContainer(_FakeHealthRepository(available: false));

      await container
          .read(healthSyncControllerProvider.notifier)
          .sync(
            bikeId: 'bike-1',
            start: DateTime(2026),
            end: DateTime(2026, 2),
          );

      final result = container.read(healthSyncControllerProvider);
      expect(result, isA<AsyncError<int>>());
      expect(
        (result! as AsyncError<int>).error,
        isA<HealthConnectNotInstalledException>(),
      );
    },
  );

  test(
    'surfaces a HealthConnectPermissionDeniedException when denied',
    () async {
      container = buildContainer(
        _FakeHealthRepository(permissionsGranted: false),
      );

      await container
          .read(healthSyncControllerProvider.notifier)
          .sync(
            bikeId: 'bike-1',
            start: DateTime(2026),
            end: DateTime(2026, 2),
          );

      final result = container.read(healthSyncControllerProvider);
      expect(
        (result! as AsyncError<int>).error,
        isA<HealthConnectPermissionDeniedException>(),
      );
    },
  );
}
