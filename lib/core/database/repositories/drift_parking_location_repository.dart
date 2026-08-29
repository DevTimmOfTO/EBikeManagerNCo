import 'package:drift/drift.dart';
import 'package:ebikemanager/core/database/app_database.dart';
import 'package:ebikemanager/core/domain/entities/parking_location.dart';
import 'package:ebikemanager/core/domain/repositories/parking_location_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'drift_parking_location_repository.g.dart';

extension ParkingLocationRowMapper on ParkingLocationRow {
  ParkingLocation toDomain() => ParkingLocation(
    id: id,
    bikeId: bikeId,
    lat: lat,
    lng: lng,
    timestamp: timestamp,
    isActive: isActive,
    note: note,
    photoPath: photoPath,
  );
}

extension ParkingLocationCompanionMapper on ParkingLocation {
  ParkingLocationsCompanion toCompanion() => ParkingLocationsCompanion.insert(
    id: id,
    bikeId: bikeId,
    lat: lat,
    lng: lng,
    timestamp: timestamp,
    isActive: Value(isActive),
    note: Value(note),
    photoPath: Value(photoPath),
  );
}

class DriftParkingLocationRepository implements ParkingLocationRepository {
  DriftParkingLocationRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<ParkingLocation?> watchActiveParkingForBike(String bikeId) => _db
      .parkingLocationDao
      .watchActiveParkingForBike(bikeId)
      .map((row) => row?.toDomain());

  @override
  Future<void> setParkedLocation(ParkingLocation location) =>
      _db.parkingLocationDao.setParkedLocation(location.toCompanion());
}

@riverpod
ParkingLocationRepository parkingLocationRepository(Ref ref) =>
    DriftParkingLocationRepository(ref.watch(appDatabaseProvider));
