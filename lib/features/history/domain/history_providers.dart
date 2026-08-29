import 'package:ebikemanager/core/database/repositories/drift_battery_history_repository.dart';
import 'package:ebikemanager/core/database/repositories/drift_trip_repository.dart';
import 'package:ebikemanager/core/domain/entities/battery_history_entry.dart';
import 'package:ebikemanager/core/domain/entities/trip.dart';
import 'package:ebikemanager/core/domain/entities/trip_point.dart';
import 'package:ebikemanager/core/health/health_connect_repository.dart';
import 'package:ebikemanager/core/logging/app_logger.dart';
import 'package:flutter/material.dart' show DateTimeRange;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'history_providers.g.dart';

const _log = AppLogger('HealthSyncController');

@riverpod
Stream<List<Trip>> tripsForBike(Ref ref, String bikeId) =>
    ref.watch(tripRepositoryProvider).watchTripsForBike(bikeId);

@riverpod
Stream<Trip?> tripById(Ref ref, String tripId) =>
    ref.watch(tripRepositoryProvider).watchTripById(tripId);

@riverpod
Stream<List<TripPoint>> tripPointsForTrip(Ref ref, String tripId) =>
    ref.watch(tripRepositoryProvider).watchPointsForTrip(tripId);

@riverpod
Stream<List<BatteryHistoryEntry>> batteryHistoryForBike(
  Ref ref,
  String bikeId,
) => ref.watch(batteryHistoryRepositoryProvider).watchEntriesForBike(bikeId);

/// `null` means "no date filter" (show everything).
@riverpod
class HistoryDateRangeFilter extends _$HistoryDateRangeFilter {
  @override
  DateTimeRange? build() => null;

  DateTimeRange? get range => state;

  set range(DateTimeRange? value) => state = value;
}

@riverpod
Future<List<Trip>> filteredTripsForBike(Ref ref, String bikeId) async {
  final trips = await ref.watch(tripsForBikeProvider(bikeId).future);
  final range = ref.watch(historyDateRangeFilterProvider);
  if (range == null) return trips;
  return trips
      .where(
        (trip) =>
            !trip.startTime.isBefore(range.start) &&
            !trip.startTime.isAfter(range.end),
      )
      .toList();
}

class HealthConnectNotInstalledException implements Exception {
  const HealthConnectNotInstalledException();
}

class HealthConnectPermissionDeniedException implements Exception {
  const HealthConnectPermissionDeniedException();
}

@Riverpod(keepAlive: true)
class HealthSyncController extends _$HealthSyncController {
  @override
  AsyncValue<int>? build() => null;

  /// Syncs Health Connect cycling sessions between [start] and [end],
  /// attaching them to [bikeId] (nullable — left unassigned otherwise), and
  /// skipping any session already imported (matched by
  /// `healthConnectRecordId`). Resolves to the count of newly imported trips.
  Future<void> sync({
    required String? bikeId,
    required DateTime start,
    required DateTime end,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final healthRepo = ref.read(healthRepositoryProvider);
      if (!await healthRepo.isHealthConnectAvailable()) {
        throw const HealthConnectNotInstalledException();
      }
      if (!await healthRepo.hasPermissions()) {
        final granted = await healthRepo.requestAuthorization();
        if (!granted) throw const HealthConnectPermissionDeniedException();
      }

      final fetched = await healthRepo.fetchCyclingTrips(
        start: start,
        end: end,
      );
      final tripRepo = ref.read(tripRepositoryProvider);
      var imported = 0;
      for (final trip in fetched) {
        final recordId = trip.healthConnectRecordId;
        if (recordId == null) continue;
        final existing = await tripRepo.findByHealthConnectRecordId(recordId);
        if (existing != null) continue;
        await tripRepo.saveTrip(trip.copyWith(bikeId: bikeId));
        imported++;
      }
      return imported;
    });
    if (state case AsyncError(:final error, :final stackTrace)) {
      _log.error('Health Connect sync failed', error, stackTrace);
    }
  }
}
