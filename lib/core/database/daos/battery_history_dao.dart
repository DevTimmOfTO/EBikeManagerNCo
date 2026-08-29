import 'package:drift/drift.dart';
import 'package:ebikemanager/core/database/app_database.dart';
import 'package:ebikemanager/core/database/tables/battery_history_entries_table.dart';

part 'battery_history_dao.g.dart';

@DriftAccessor(tables: [BatteryHistoryEntries])
class BatteryHistoryDao extends DatabaseAccessor<AppDatabase>
    with _$BatteryHistoryDaoMixin {
  BatteryHistoryDao(super.attachedDatabase);

  Stream<List<BatteryHistoryEntryRow>> watchEntriesForBike(String bikeId) =>
      (select(batteryHistoryEntries)
            ..where((e) => e.bikeId.equals(bikeId))
            ..orderBy([(e) => OrderingTerm.desc(e.timestamp)]))
          .watch();

  Stream<BatteryHistoryEntryRow?> watchLatestEntryForBike(String bikeId) =>
      (select(batteryHistoryEntries)
            ..where((e) => e.bikeId.equals(bikeId))
            ..orderBy([(e) => OrderingTerm.desc(e.timestamp)])
            ..limit(1))
          .watchSingleOrNull();

  Future<void> insertEntry(BatteryHistoryEntriesCompanion entry) =>
      into(batteryHistoryEntries).insertOnConflictUpdate(entry);

  Future<void> deleteEntry(String id) =>
      (delete(batteryHistoryEntries)..where((e) => e.id.equals(id))).go();
}
