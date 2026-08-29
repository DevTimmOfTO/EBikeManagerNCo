import 'package:drift/drift.dart';
import 'package:ebikemanager/core/database/app_database.dart';
import 'package:ebikemanager/core/domain/entities/bike.dart';
import 'package:ebikemanager/core/domain/repositories/bike_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'drift_bike_repository.g.dart';

extension BikeRowMapper on BikeRow {
  Bike toDomain() => Bike(
    id: id,
    nickname: nickname,
    createdAt: createdAt,
    updatedAt: updatedAt,
    manufacturer: manufacturer,
    model: model,
    colour: colour,
    purchaseDate: purchaseDate,
    adfcCode: adfcCode,
    adfcCodePhotoPath: adfcCodePhotoPath,
    frameSize: frameSize,
    wheelSize: wheelSize,
    motorType: motorType,
    motorWattage: motorWattage,
    batteryCapacityWh: batteryCapacityWh,
    batteryPurchaseDate: batteryPurchaseDate,
    purchasePriceCents: purchasePriceCents,
    photoPath: photoPath,
    notes: notes,
    isArchived: isArchived,
  );
}

extension BikeCompanionMapper on Bike {
  BikesCompanion toCompanion() => BikesCompanion.insert(
    id: id,
    nickname: nickname,
    createdAt: createdAt,
    updatedAt: updatedAt,
    manufacturer: Value(manufacturer),
    model: Value(model),
    colour: Value(colour),
    purchaseDate: Value(purchaseDate),
    adfcCode: Value(adfcCode),
    adfcCodePhotoPath: Value(adfcCodePhotoPath),
    frameSize: Value(frameSize),
    wheelSize: Value(wheelSize),
    motorType: Value(motorType),
    motorWattage: Value(motorWattage),
    batteryCapacityWh: Value(batteryCapacityWh),
    batteryPurchaseDate: Value(batteryPurchaseDate),
    purchasePriceCents: Value(purchasePriceCents),
    photoPath: Value(photoPath),
    notes: Value(notes),
    isArchived: Value(isArchived),
  );
}

class DriftBikeRepository implements BikeRepository {
  DriftBikeRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<Bike>> watchNonArchivedBikes() => _db.bikeDao
      .watchNonArchivedBikes()
      .map((rows) => rows.map((r) => r.toDomain()).toList());

  @override
  Stream<List<Bike>> watchAllBikes() => _db.bikeDao
      .watchAllBikes()
      .map((rows) => rows.map((r) => r.toDomain()).toList());

  @override
  Stream<Bike?> watchBikeById(String id) =>
      _db.bikeDao.watchBikeById(id).map((row) => row?.toDomain());

  @override
  Future<Bike?> getBikeById(String id) async =>
      (await _db.bikeDao.getBikeById(id))?.toDomain();

  @override
  Future<void> saveBike(Bike bike) =>
      _db.bikeDao.upsertBike(bike.toCompanion());

  @override
  Future<void> deleteBike(String id) => _db.bikeDao.deleteBike(id);
}

@riverpod
BikeRepository bikeRepository(Ref ref) =>
    DriftBikeRepository(ref.watch(appDatabaseProvider));
