import 'package:ebikemanager/core/domain/enums.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'battery_history_entry.freezed.dart';
part 'battery_history_entry.g.dart';

@freezed
abstract class BatteryHistoryEntry with _$BatteryHistoryEntry {
  const factory BatteryHistoryEntry({
    required String id,
    required String bikeId,
    required DateTime timestamp,
    required BatteryEventType eventType,
    required DateTime createdAt,
    required DateTime updatedAt,
    int? stateOfChargeStart,
    int? stateOfChargeEnd,
    int? estimatedCycleCount,
    double? estimatedHealthPct,
    String? notes,
  }) = _BatteryHistoryEntry;

  factory BatteryHistoryEntry.fromJson(Map<String, Object?> json) =>
      _$BatteryHistoryEntryFromJson(json);
}
