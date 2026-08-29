import 'package:drift/drift.dart';
import 'package:ebikemanager/core/database/tables/bikes_table.dart';

@DataClassName('ParkingLocationRow')
class ParkingLocations extends Table {
  TextColumn get id => text()();
  TextColumn get bikeId =>
      text().references(Bikes, #id, onDelete: KeyAction.cascade)();
  RealColumn get lat => real()();
  RealColumn get lng => real()();
  DateTimeColumn get timestamp => dateTime()();
  TextColumn get note => text().nullable()();
  TextColumn get photoPath => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}
