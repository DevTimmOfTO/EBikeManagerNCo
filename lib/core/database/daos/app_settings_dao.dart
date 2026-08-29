import 'package:drift/drift.dart';
import 'package:ebikemanager/core/database/app_database.dart';
import 'package:ebikemanager/core/database/tables/app_settings_table.dart';

part 'app_settings_dao.g.dart';

@DriftAccessor(tables: [AppSettingsTable])
class AppSettingsDao extends DatabaseAccessor<AppDatabase>
    with _$AppSettingsDaoMixin {
  AppSettingsDao(super.attachedDatabase);

  /// There's always exactly one settings row — created by [AppDatabase]'s
  /// `onCreate` migration — so this always resolves to a value. Its `id` is
  /// whatever SQLite's rowid auto-assignment picked (typically `1`); nothing
  /// depends on that value, so queries here don't filter on it.
  Stream<AppSettingsRow> watchSettings() =>
      select(appSettingsTable).watchSingle();

  Future<void> updateSettings(AppSettingsTableCompanion entry) =>
      update(appSettingsTable).write(entry);
}
