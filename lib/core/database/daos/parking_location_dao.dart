import 'package:drift/drift.dart';
import 'package:ebikemanager/core/database/app_database.dart';
import 'package:ebikemanager/core/database/tables/parking_locations_table.dart';

part 'parking_location_dao.g.dart';

@DriftAccessor(tables: [ParkingLocations])
class ParkingLocationDao extends DatabaseAccessor<AppDatabase>
    with _$ParkingLocationDaoMixin {
  ParkingLocationDao(super.attachedDatabase);

  Stream<ParkingLocationRow?> watchActiveParkingForBike(String bikeId) =>
      (select(parkingLocations)
            ..where((p) => p.bikeId.equals(bikeId) & p.isActive.equals(true)))
          .watchSingleOrNull();

  /// Deactivates any existing active pin for `entry.bikeId` and inserts
  /// [entry] as the new active pin, in a single transaction.
  Future<void> setParkedLocation(ParkingLocationsCompanion entry) =>
      transaction(() async {
        final bikeId = entry.bikeId.value;
        await (update(parkingLocations)..where(
              (p) => p.bikeId.equals(bikeId) & p.isActive.equals(true),
            ))
            .write(const ParkingLocationsCompanion(isActive: Value(false)));
        await into(parkingLocations).insert(entry);
      });
}
