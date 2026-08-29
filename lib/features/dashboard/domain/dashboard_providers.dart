import 'package:ebikemanager/core/database/repositories/drift_battery_history_repository.dart';
import 'package:ebikemanager/core/database/repositories/drift_trip_repository.dart';
import 'package:ebikemanager/core/domain/entities/battery_history_entry.dart';
import 'package:ebikemanager/core/domain/entities/trip.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dashboard_providers.g.dart';

@riverpod
Stream<BatteryHistoryEntry?> latestBatteryEntryForBike(
  Ref ref,
  String bikeId,
) =>
    ref.watch(batteryHistoryRepositoryProvider).watchLatestEntryForBike(bikeId);

@riverpod
Stream<Trip?> latestTripForBike(Ref ref, String bikeId) =>
    ref.watch(tripRepositoryProvider).watchLatestTripForBike(bikeId);
