import 'package:ebikemanager/core/domain/entities/battery_history_entry.dart';
import 'package:ebikemanager/core/domain/entities/bike.dart';
import 'package:ebikemanager/core/domain/entities/parking_location.dart';
import 'package:ebikemanager/core/domain/entities/trip.dart';
import 'package:ebikemanager/core/domain/entities/trip_point.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_data_bundle.freezed.dart';
part 'app_data_bundle.g.dart';

/// A full export of the user's bike data (bikes, trips, battery history,
/// parking pins) — deliberately excludes `AppSettings`, since display
/// name/theme/units are per-install preferences, not data to carry between
/// devices or restore from a backup.
@freezed
abstract class AppDataBundle with _$AppDataBundle {
  const factory AppDataBundle({
    required int schemaVersion,
    required DateTime exportedAt,
    required List<Bike> bikes,
    required List<Trip> trips,
    required List<TripPoint> tripPoints,
    required List<BatteryHistoryEntry> batteryHistoryEntries,
    required List<ParkingLocation> parkingLocations,
  }) = _AppDataBundle;

  factory AppDataBundle.fromJson(Map<String, Object?> json) =>
      _$AppDataBundleFromJson(json);
}
