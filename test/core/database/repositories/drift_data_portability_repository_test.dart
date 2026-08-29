import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:ebikemanager/core/database/app_database.dart';
import 'package:ebikemanager/core/database/repositories/drift_battery_history_repository.dart';
import 'package:ebikemanager/core/database/repositories/drift_bike_repository.dart';
import 'package:ebikemanager/core/database/repositories/drift_data_portability_repository.dart';
import 'package:ebikemanager/core/database/repositories/drift_parking_location_repository.dart';
import 'package:ebikemanager/core/database/repositories/drift_trip_repository.dart';
import 'package:ebikemanager/core/domain/entities/app_data_bundle.dart';
import 'package:ebikemanager/core/domain/entities/battery_history_entry.dart';
import 'package:ebikemanager/core/domain/entities/bike.dart';
import 'package:ebikemanager/core/domain/entities/parking_location.dart';
import 'package:ebikemanager/core/domain/entities/trip.dart';
import 'package:ebikemanager/core/domain/entities/trip_point.dart';
import 'package:ebikemanager/core/domain/enums.dart';
import 'package:ebikemanager/core/domain/repositories/data_portability_repository.dart';
import 'package:flutter_test/flutter_test.dart';

Bike _bike(String id, String nickname) {
  final now = DateTime(2026);
  return Bike(id: id, nickname: nickname, createdAt: now, updatedAt: now);
}

Trip _trip(String id, String bikeId) {
  final now = DateTime(2026);
  return Trip(
    id: id,
    bikeId: bikeId,
    startTime: now,
    source: TripSource.manual,
    createdAt: now,
    updatedAt: now,
    distanceMeters: 1000,
  );
}

BatteryHistoryEntry _batteryEntry(String id, String bikeId) {
  final now = DateTime(2026);
  return BatteryHistoryEntry(
    id: id,
    bikeId: bikeId,
    timestamp: now,
    eventType: BatteryEventType.chargeCycle,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;
  late DriftDataPortabilityRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = DriftDataPortabilityRepository(db);
  });

  tearDown(() => db.close());

  test('exportAll reflects everything currently in the database', () async {
    await db.bikeDao.upsertBike(_bike('bike-1', 'Blitz').toCompanion());
    await db.tripDao.upsertTrip(_trip('trip-1', 'bike-1').toCompanion());
    await db.tripDao.insertTripPoints([
      const TripPoint(
        id: 'point-1',
        tripId: 'trip-1',
        sequenceIndex: 0,
        lat: 51.5,
        lng: 10.5,
      ).toCompanion(),
    ]);
    await db.batteryHistoryDao.insertEntry(
      _batteryEntry('entry-1', 'bike-1').toCompanion(),
    );
    await db.parkingLocationDao.setParkedLocation(
      ParkingLocation(
        id: 'pin-1',
        bikeId: 'bike-1',
        lat: 51.5,
        lng: 10.5,
        timestamp: DateTime(2026),
      ).toCompanion(),
    );

    final bundle = await repo.exportAll();

    expect(bundle.bikes.map((b) => b.id), ['bike-1']);
    expect(bundle.trips.map((t) => t.id), ['trip-1']);
    expect(bundle.tripPoints.map((p) => p.id), ['point-1']);
    expect(bundle.batteryHistoryEntries.map((e) => e.id), ['entry-1']);
    expect(bundle.parkingLocations.map((p) => p.id), ['pin-1']);
  });

  test('merge import upserts by id without touching untouched rows', () async {
    await db.bikeDao.upsertBike(_bike('bike-1', 'Blitz').toCompanion());
    await db.bikeDao.upsertBike(_bike('bike-2', 'Onlyhere').toCompanion());

    final bundle = AppDataBundle(
      schemaVersion: currentAppDataBundleSchemaVersion,
      exportedAt: DateTime(2026),
      bikes: [_bike('bike-1', 'Renamed'), _bike('bike-3', 'NewFromImport')],
      trips: const [],
      tripPoints: const [],
      batteryHistoryEntries: const [],
      parkingLocations: const [],
    );

    await repo.importAll(bundle, overwrite: false);

    final bikes = await db.select(db.bikes).get();
    final byId = {for (final b in bikes) b.id: b.nickname};
    expect(byId, {
      'bike-1': 'Renamed',
      'bike-2': 'Onlyhere',
      'bike-3': 'NewFromImport',
    });
  });

  test('overwrite import replaces all existing bike data', () async {
    await db.bikeDao.upsertBike(_bike('old-bike', 'Old').toCompanion());
    await db.tripDao.upsertTrip(_trip('old-trip', 'old-bike').toCompanion());

    final bundle = AppDataBundle(
      schemaVersion: currentAppDataBundleSchemaVersion,
      exportedAt: DateTime(2026),
      bikes: [_bike('new-bike', 'New')],
      trips: const [],
      tripPoints: const [],
      batteryHistoryEntries: const [],
      parkingLocations: const [],
    );

    await repo.importAll(bundle, overwrite: true);

    final bikes = await db.select(db.bikes).get();
    final trips = await db.select(db.trips).get();
    expect(bikes.map((b) => b.id), ['new-bike']);
    expect(trips, isEmpty);
  });

  test('clearAllData removes every bike, trip, and battery entry', () async {
    await db.bikeDao.upsertBike(_bike('bike-1', 'Blitz').toCompanion());
    await db.tripDao.upsertTrip(_trip('trip-1', 'bike-1').toCompanion());
    await db.batteryHistoryDao.insertEntry(
      _batteryEntry('entry-1', 'bike-1').toCompanion(),
    );

    await repo.clearAllData();

    expect(await db.select(db.bikes).get(), isEmpty);
    expect(await db.select(db.trips).get(), isEmpty);
    expect(await db.select(db.batteryHistoryEntries).get(), isEmpty);
  });
}
