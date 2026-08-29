import 'package:drift/drift.dart';
import 'package:ebikemanager/core/database/tables/trips_table.dart';

@DataClassName('TripPointRow')
class TripPoints extends Table {
  TextColumn get id => text()();
  TextColumn get tripId =>
      text().references(Trips, #id, onDelete: KeyAction.cascade)();
  IntColumn get sequenceIndex => integer()();
  RealColumn get lat => real()();
  RealColumn get lng => real()();
  RealColumn get elevationMeters => real().nullable()();
  DateTimeColumn get timestamp => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
