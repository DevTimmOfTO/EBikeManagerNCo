import 'package:ebikemanager/core/domain/entities/battery_history_entry.dart';

abstract class BatteryHistoryRepository {
  Stream<List<BatteryHistoryEntry>> watchEntriesForBike(String bikeId);

  Stream<BatteryHistoryEntry?> watchLatestEntryForBike(String bikeId);

  Future<void> saveEntry(BatteryHistoryEntry entry);

  Future<void> deleteEntry(String id);
}
