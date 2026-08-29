import 'package:drift/drift.dart';
import 'package:ebikemanager/core/database/app_database.dart';
import 'package:ebikemanager/core/domain/entities/battery_history_entry.dart';
import 'package:ebikemanager/core/domain/repositories/battery_history_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'drift_battery_history_repository.g.dart';

extension BatteryHistoryEntryRowMapper on BatteryHistoryEntryRow {
  BatteryHistoryEntry toDomain() => BatteryHistoryEntry(
    id: id,
    bikeId: bikeId,
    timestamp: timestamp,
    eventType: eventType,
    createdAt: createdAt,
    updatedAt: updatedAt,
    stateOfChargeStart: stateOfChargeStart,
    stateOfChargeEnd: stateOfChargeEnd,
    estimatedCycleCount: estimatedCycleCount,
    estimatedHealthPct: estimatedHealthPct,
    notes: notes,
  );
}

extension BatteryHistoryEntryCompanionMapper on BatteryHistoryEntry {
  BatteryHistoryEntriesCompanion toCompanion() =>
      BatteryHistoryEntriesCompanion.insert(
        id: id,
        bikeId: bikeId,
        timestamp: timestamp,
        eventType: eventType,
        createdAt: createdAt,
        updatedAt: updatedAt,
        stateOfChargeStart: Value(stateOfChargeStart),
        stateOfChargeEnd: Value(stateOfChargeEnd),
        estimatedCycleCount: Value(estimatedCycleCount),
        estimatedHealthPct: Value(estimatedHealthPct),
        notes: Value(notes),
      );
}

class DriftBatteryHistoryRepository implements BatteryHistoryRepository {
  DriftBatteryHistoryRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<BatteryHistoryEntry>> watchEntriesForBike(String bikeId) => _db
      .batteryHistoryDao
      .watchEntriesForBike(bikeId)
      .map((rows) => rows.map((r) => r.toDomain()).toList());

  @override
  Stream<BatteryHistoryEntry?> watchLatestEntryForBike(String bikeId) => _db
      .batteryHistoryDao
      .watchLatestEntryForBike(bikeId)
      .map((row) => row?.toDomain());

  @override
  Future<void> saveEntry(BatteryHistoryEntry entry) =>
      _db.batteryHistoryDao.insertEntry(entry.toCompanion());

  @override
  Future<void> deleteEntry(String id) => _db.batteryHistoryDao.deleteEntry(id);
}

@riverpod
BatteryHistoryRepository batteryHistoryRepository(Ref ref) =>
    DriftBatteryHistoryRepository(ref.watch(appDatabaseProvider));
