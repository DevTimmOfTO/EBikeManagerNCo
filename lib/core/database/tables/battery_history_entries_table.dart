import 'package:drift/drift.dart';
import 'package:ebikemanager/core/database/tables/bikes_table.dart';
import 'package:ebikemanager/core/domain/enums.dart';

@DataClassName('BatteryHistoryEntryRow')
class BatteryHistoryEntries extends Table {
  TextColumn get id => text()();
  TextColumn get bikeId =>
      text().references(Bikes, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get timestamp => dateTime()();
  TextColumn get eventType => textEnum<BatteryEventType>()();
  IntColumn get stateOfChargeStart => integer().nullable()();
  IntColumn get stateOfChargeEnd => integer().nullable()();
  IntColumn get estimatedCycleCount => integer().nullable()();
  RealColumn get estimatedHealthPct => real().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
