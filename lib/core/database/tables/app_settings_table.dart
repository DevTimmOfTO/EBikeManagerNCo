import 'package:drift/drift.dart';
import 'package:ebikemanager/core/database/tables/bikes_table.dart';
import 'package:ebikemanager/core/domain/enums.dart';

/// Single-row table: `AppDatabase`'s `onCreate` migration inserts the one
/// row this app ever reads or writes; its `id` isn't otherwise meaningful.
@DataClassName('AppSettingsRow')
class AppSettingsTable extends Table {
  @override
  String get tableName => 'app_settings';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get displayName => text().nullable()();
  TextColumn get avatarPath => text().nullable()();
  TextColumn get unitSystem =>
      textEnum<UnitSystem>().withDefault(Constant(UnitSystem.metric.name))();
  TextColumn get themePreference => textEnum<ThemePreference>().withDefault(
    Constant(ThemePreference.system.name),
  )();
  TextColumn get defaultBikeId =>
      text().nullable().references(Bikes, #id, onDelete: KeyAction.setNull)();
  BoolColumn get healthSyncEnabled =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get showBicycleShopsLayer =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get showRepairStationsLayer =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get showChargingStationsLayer =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get showCyclewaysLayer =>
      boolean().withDefault(const Constant(true))();
  DateTimeColumn get updatedAt => dateTime()();
}
