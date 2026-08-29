import 'package:ebikemanager/core/database/app_database.dart';
import 'package:ebikemanager/core/database/repositories/drift_battery_history_repository.dart';
import 'package:ebikemanager/core/database/repositories/drift_bike_repository.dart';
import 'package:ebikemanager/core/database/repositories/drift_parking_location_repository.dart';
import 'package:ebikemanager/core/database/repositories/drift_trip_repository.dart';
import 'package:ebikemanager/core/domain/entities/app_data_bundle.dart';
import 'package:ebikemanager/core/domain/repositories/data_portability_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'drift_data_portability_repository.g.dart';

class DriftDataPortabilityRepository implements DataPortabilityRepository {
  DriftDataPortabilityRepository(this._db);

  final AppDatabase _db;

  @override
  Future<AppDataBundle> exportAll() async {
    final bikes = await _db.select(_db.bikes).get();
    final trips = await _db.select(_db.trips).get();
    final tripPoints = await _db.select(_db.tripPoints).get();
    final batteryHistoryEntries = await _db
        .select(_db.batteryHistoryEntries)
        .get();
    final parkingLocations = await _db.select(_db.parkingLocations).get();

    return AppDataBundle(
      schemaVersion: currentAppDataBundleSchemaVersion,
      exportedAt: DateTime.now(),
      bikes: bikes.map((r) => r.toDomain()).toList(),
      trips: trips.map((r) => r.toDomain()).toList(),
      tripPoints: tripPoints.map((r) => r.toDomain()).toList(),
      batteryHistoryEntries: batteryHistoryEntries
          .map((r) => r.toDomain())
          .toList(),
      parkingLocations: parkingLocations.map((r) => r.toDomain()).toList(),
    );
  }

  @override
  Future<void> importAll(
    AppDataBundle bundle, {
    required bool overwrite,
  }) => _db.transaction(() async {
    if (overwrite) {
      await _deleteAll();
    }
    await _db.batch((b) {
      b
        ..insertAllOnConflictUpdate(
          _db.bikes,
          bundle.bikes.map((e) => e.toCompanion()),
        )
        ..insertAllOnConflictUpdate(
          _db.trips,
          bundle.trips.map((e) => e.toCompanion()),
        )
        ..insertAllOnConflictUpdate(
          _db.tripPoints,
          bundle.tripPoints.map((e) => e.toCompanion()),
        )
        ..insertAllOnConflictUpdate(
          _db.batteryHistoryEntries,
          bundle.batteryHistoryEntries.map((e) => e.toCompanion()),
        )
        ..insertAllOnConflictUpdate(
          _db.parkingLocations,
          bundle.parkingLocations.map((e) => e.toCompanion()),
        );
    });
  });

  @override
  Future<void> clearAllData() => _db.transaction(_deleteAll);

  /// Deletes children before parents so this is safe regardless of the
  /// cascade rules, and so it also removes trips with no `bikeId` at all
  /// (Health Connect imports not yet attached to a bike).
  Future<void> _deleteAll() async {
    await _db.delete(_db.tripPoints).go();
    await _db.delete(_db.trips).go();
    await _db.delete(_db.batteryHistoryEntries).go();
    await _db.delete(_db.parkingLocations).go();
    await _db.delete(_db.bikes).go();
  }
}

@riverpod
DataPortabilityRepository dataPortabilityRepository(Ref ref) =>
    DriftDataPortabilityRepository(ref.watch(appDatabaseProvider));
