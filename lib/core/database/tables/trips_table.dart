import 'package:drift/drift.dart';
import 'package:ebikemanager/core/database/tables/bikes_table.dart';
import 'package:ebikemanager/core/domain/enums.dart';

@DataClassName('TripRow')
class Trips extends Table {
  TextColumn get id => text()();
  TextColumn get bikeId =>
      text().nullable().references(Bikes, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime().nullable()();
  RealColumn get distanceMeters => real().nullable()();
  IntColumn get durationSeconds => integer().nullable()();
  RealColumn get avgSpeedKmh => real().nullable()();
  RealColumn get elevationGainMeters => real().nullable()();
  RealColumn get caloriesKcal => real().nullable()();
  IntColumn get activeMinutes => integer().nullable()();
  IntColumn get heartRateAvgBpm => integer().nullable()();
  TextColumn get healthConnectRecordId => text().nullable().unique()();
  TextColumn get source => textEnum<TripSource>()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
