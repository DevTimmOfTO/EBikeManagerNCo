import 'package:drift/drift.dart';
import 'package:ebikemanager/core/database/app_database.dart';
import 'package:ebikemanager/core/database/tables/trip_points_table.dart';
import 'package:ebikemanager/core/database/tables/trips_table.dart';

part 'trip_dao.g.dart';

@DriftAccessor(tables: [Trips, TripPoints])
class TripDao extends DatabaseAccessor<AppDatabase> with _$TripDaoMixin {
  TripDao(super.attachedDatabase);

  Stream<List<TripRow>> watchTripsForBike(String bikeId) =>
      (select(trips)
            ..where((t) => t.bikeId.equals(bikeId))
            ..orderBy([(t) => OrderingTerm.desc(t.startTime)]))
          .watch();

  Stream<List<TripRow>> watchAllTrips() =>
      (select(trips)..orderBy([(t) => OrderingTerm.desc(t.startTime)])).watch();

  Stream<TripRow?> watchTripById(String id) =>
      (select(trips)..where((t) => t.id.equals(id))).watchSingleOrNull();

  Stream<TripRow?> watchLatestTripForBike(String bikeId) =>
      (select(trips)
            ..where((t) => t.bikeId.equals(bikeId))
            ..orderBy([(t) => OrderingTerm.desc(t.startTime)])
            ..limit(1))
          .watchSingleOrNull();

  Future<TripRow?> findByHealthConnectRecordId(String recordId) => (select(
    trips,
  )..where((t) => t.healthConnectRecordId.equals(recordId))).getSingleOrNull();

  Stream<List<TripPointRow>> watchPointsForTrip(String tripId) =>
      (select(tripPoints)
            ..where((p) => p.tripId.equals(tripId))
            ..orderBy([(p) => OrderingTerm.asc(p.sequenceIndex)]))
          .watch();

  Future<void> upsertTrip(TripsCompanion entry) =>
      into(trips).insertOnConflictUpdate(entry);

  Future<void> insertTripPoints(List<TripPointsCompanion> points) =>
      batch((b) => b.insertAll(tripPoints, points));

  Future<void> deleteTrip(String id) =>
      (delete(trips)..where((t) => t.id.equals(id))).go();
}
