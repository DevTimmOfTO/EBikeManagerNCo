import 'package:drift/drift.dart';
import 'package:ebikemanager/core/database/app_database.dart';
import 'package:ebikemanager/core/domain/entities/trip.dart';
import 'package:ebikemanager/core/domain/entities/trip_point.dart';
import 'package:ebikemanager/core/domain/repositories/trip_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'drift_trip_repository.g.dart';

extension TripRowMapper on TripRow {
  Trip toDomain() => Trip(
    id: id,
    startTime: startTime,
    source: source,
    createdAt: createdAt,
    updatedAt: updatedAt,
    bikeId: bikeId,
    endTime: endTime,
    distanceMeters: distanceMeters,
    durationSeconds: durationSeconds,
    avgSpeedKmh: avgSpeedKmh,
    elevationGainMeters: elevationGainMeters,
    caloriesKcal: caloriesKcal,
    activeMinutes: activeMinutes,
    heartRateAvgBpm: heartRateAvgBpm,
    healthConnectRecordId: healthConnectRecordId,
  );
}

extension TripCompanionMapper on Trip {
  TripsCompanion toCompanion() => TripsCompanion.insert(
    id: id,
    startTime: startTime,
    source: source,
    createdAt: createdAt,
    updatedAt: updatedAt,
    bikeId: Value(bikeId),
    endTime: Value(endTime),
    distanceMeters: Value(distanceMeters),
    durationSeconds: Value(durationSeconds),
    avgSpeedKmh: Value(avgSpeedKmh),
    elevationGainMeters: Value(elevationGainMeters),
    caloriesKcal: Value(caloriesKcal),
    activeMinutes: Value(activeMinutes),
    heartRateAvgBpm: Value(heartRateAvgBpm),
    healthConnectRecordId: Value(healthConnectRecordId),
  );
}

extension TripPointRowMapper on TripPointRow {
  TripPoint toDomain() => TripPoint(
    id: id,
    tripId: tripId,
    sequenceIndex: sequenceIndex,
    lat: lat,
    lng: lng,
    elevationMeters: elevationMeters,
    timestamp: timestamp,
  );
}

extension TripPointCompanionMapper on TripPoint {
  TripPointsCompanion toCompanion() => TripPointsCompanion.insert(
    id: id,
    tripId: tripId,
    sequenceIndex: sequenceIndex,
    lat: lat,
    lng: lng,
    elevationMeters: Value(elevationMeters),
    timestamp: Value(timestamp),
  );
}

class DriftTripRepository implements TripRepository {
  DriftTripRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<Trip>> watchTripsForBike(String bikeId) => _db.tripDao
      .watchTripsForBike(bikeId)
      .map((rows) => rows.map((r) => r.toDomain()).toList());

  @override
  Stream<List<Trip>> watchAllTrips() => _db.tripDao.watchAllTrips().map(
    (rows) => rows.map((r) => r.toDomain()).toList(),
  );

  @override
  Stream<Trip?> watchTripById(String id) =>
      _db.tripDao.watchTripById(id).map((row) => row?.toDomain());

  @override
  Stream<Trip?> watchLatestTripForBike(String bikeId) =>
      _db.tripDao.watchLatestTripForBike(bikeId).map((row) => row?.toDomain());

  @override
  Future<Trip?> findByHealthConnectRecordId(String recordId) async =>
      (await _db.tripDao.findByHealthConnectRecordId(recordId))?.toDomain();

  @override
  Stream<List<TripPoint>> watchPointsForTrip(String tripId) => _db.tripDao
      .watchPointsForTrip(tripId)
      .map((rows) => rows.map((r) => r.toDomain()).toList());

  @override
  Future<void> saveTrip(Trip trip, {List<TripPoint> points = const []}) async {
    await _db.tripDao.upsertTrip(trip.toCompanion());
    if (points.isNotEmpty) {
      await _db.tripDao.insertTripPoints(
        points.map((p) => p.toCompanion()).toList(),
      );
    }
  }

  @override
  Future<void> deleteTrip(String id) => _db.tripDao.deleteTrip(id);
}

@riverpod
TripRepository tripRepository(Ref ref) =>
    DriftTripRepository(ref.watch(appDatabaseProvider));
