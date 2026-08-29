import 'dart:async';

import 'package:ebikemanager/core/domain/entities/trip.dart';
import 'package:ebikemanager/core/domain/enums.dart';
import 'package:ebikemanager/core/health/health_repository.dart';
import 'package:ebikemanager/core/logging/app_logger.dart';
import 'package:health/health.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'health_connect_repository.g.dart';

const Set<HealthWorkoutActivityType> _cyclingActivityTypes = {
  HealthWorkoutActivityType.BIKING,
  HealthWorkoutActivityType.BIKING_STATIONARY,
};

class HealthConnectRepository implements HealthRepository {
  HealthConnectRepository() {
    unawaited(_health.configure());
  }

  // Reading WORKOUT also makes the plugin read DistanceRecord and
  // TotalCaloriesBurnedRecord under the hood to enrich each session, so all
  // three types must be authorized or the read throws a SecurityException.
  static const List<HealthDataType> _types = [
    HealthDataType.WORKOUT,
    HealthDataType.DISTANCE_DELTA,
    HealthDataType.TOTAL_CALORIES_BURNED,
  ];
  static const AppLogger _log = AppLogger('HealthConnectRepository');

  final Health _health = Health();
  final Uuid _uuid = const Uuid();

  @override
  Future<bool> isHealthConnectAvailable() => _health.isHealthConnectAvailable();

  @override
  Future<void> promptInstallHealthConnect() => _health.installHealthConnect();

  @override
  Future<bool> hasPermissions() async =>
      await _health.hasPermissions(
        _types,
        permissions: List.filled(_types.length, HealthDataAccess.READ),
      ) ??
      false;

  @override
  Future<bool> requestAuthorization() => _health.requestAuthorization(
    _types,
    permissions: List.filled(_types.length, HealthDataAccess.READ),
  );

  @override
  Future<List<Trip>> fetchCyclingTrips({
    required DateTime start,
    required DateTime end,
  }) async {
    final dataPoints = await _health.getHealthDataFromTypes(
      types: _types,
      startTime: start,
      endTime: end,
    );

    final trips = <Trip>[];
    for (final point in dataPoints) {
      final value = point.value;
      if (value is! WorkoutHealthValue ||
          !_cyclingActivityTypes.contains(value.workoutActivityType)) {
        continue;
      }

      final now = DateTime.now();
      final durationSeconds = point.dateTo.difference(point.dateFrom).inSeconds;
      final distanceMeters = value.totalDistanceUnit == HealthDataUnit.METER
          ? value.totalDistance?.toDouble()
          : null;
      if (value.totalDistance != null && distanceMeters == null) {
        _log.warning(
          'Unexpected distance unit ${value.totalDistanceUnit}, '
          'dropping distance',
        );
      }

      trips.add(
        Trip(
          id: _uuid.v4(),
          startTime: point.dateFrom,
          endTime: point.dateTo,
          source: TripSource.healthConnect,
          createdAt: now,
          updatedAt: now,
          distanceMeters: distanceMeters,
          durationSeconds: durationSeconds,
          avgSpeedKmh: distanceMeters != null && durationSeconds > 0
              ? (distanceMeters / 1000) / (durationSeconds / 3600)
              : null,
          caloriesKcal:
              value.totalEnergyBurnedUnit == HealthDataUnit.KILOCALORIE
              ? value.totalEnergyBurned?.toDouble()
              : null,
          healthConnectRecordId: point.uuid,
        ),
      );
    }
    return trips;
  }
}

@Riverpod(keepAlive: true)
HealthRepository healthRepository(Ref ref) => HealthConnectRepository();
