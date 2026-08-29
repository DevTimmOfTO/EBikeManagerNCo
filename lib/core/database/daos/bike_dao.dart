import 'package:drift/drift.dart';
import 'package:ebikemanager/core/database/app_database.dart';
import 'package:ebikemanager/core/database/tables/bikes_table.dart';

part 'bike_dao.g.dart';

@DriftAccessor(tables: [Bikes])
class BikeDao extends DatabaseAccessor<AppDatabase> with _$BikeDaoMixin {
  BikeDao(super.attachedDatabase);

  Stream<List<BikeRow>> watchNonArchivedBikes() =>
      (select(bikes)..where((b) => b.isArchived.equals(false))).watch();

  Stream<List<BikeRow>> watchAllBikes() =>
      (select(bikes)..orderBy([(b) => OrderingTerm.asc(b.nickname)])).watch();

  Stream<BikeRow?> watchBikeById(String id) =>
      (select(bikes)..where((b) => b.id.equals(id))).watchSingleOrNull();

  Future<BikeRow?> getBikeById(String id) =>
      (select(bikes)..where((b) => b.id.equals(id))).getSingleOrNull();

  Future<void> upsertBike(BikesCompanion entry) =>
      into(bikes).insertOnConflictUpdate(entry);

  Future<void> deleteBike(String id) =>
      (delete(bikes)..where((b) => b.id.equals(id))).go();
}
