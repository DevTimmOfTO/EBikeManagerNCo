import 'package:drift/drift.dart';

@DataClassName('BikeRow')
class Bikes extends Table {
  TextColumn get id => text()();
  TextColumn get nickname => text()();
  TextColumn get manufacturer => text().nullable()();
  TextColumn get model => text().nullable()();
  TextColumn get colour => text().nullable()();
  DateTimeColumn get purchaseDate => dateTime().nullable()();
  TextColumn get adfcCode => text().nullable()();
  TextColumn get adfcCodePhotoPath => text().nullable()();
  TextColumn get frameSize => text().nullable()();
  TextColumn get wheelSize => text().nullable()();
  TextColumn get motorType => text().nullable()();
  IntColumn get motorWattage => integer().nullable()();
  IntColumn get batteryCapacityWh => integer().nullable()();
  DateTimeColumn get batteryPurchaseDate => dateTime().nullable()();
  IntColumn get purchasePriceCents => integer().nullable()();
  TextColumn get photoPath => text().nullable()();
  TextColumn get notes => text().nullable()();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
