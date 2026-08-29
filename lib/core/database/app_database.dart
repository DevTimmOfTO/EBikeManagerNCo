import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:ebikemanager/core/database/daos/app_settings_dao.dart';
import 'package:ebikemanager/core/database/daos/battery_history_dao.dart';
import 'package:ebikemanager/core/database/daos/bike_dao.dart';
import 'package:ebikemanager/core/database/daos/parking_location_dao.dart';
import 'package:ebikemanager/core/database/daos/trip_dao.dart';
import 'package:ebikemanager/core/database/tables/app_settings_table.dart';
import 'package:ebikemanager/core/database/tables/battery_history_entries_table.dart';
import 'package:ebikemanager/core/database/tables/bikes_table.dart';
import 'package:ebikemanager/core/database/tables/parking_locations_table.dart';
import 'package:ebikemanager/core/database/tables/trip_points_table.dart';
import 'package:ebikemanager/core/database/tables/trips_table.dart';
import 'package:ebikemanager/core/domain/enums.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Bikes,
    BatteryHistoryEntries,
    Trips,
    TripPoints,
    ParkingLocations,
    AppSettingsTable,
  ],
  daos: [
    BikeDao,
    BatteryHistoryDao,
    TripDao,
    ParkingLocationDao,
    AppSettingsDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'ebikemanager'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await into(appSettingsTable).insert(
        AppSettingsTableCompanion.insert(updatedAt: DateTime.now()),
      );
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}

@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
}
