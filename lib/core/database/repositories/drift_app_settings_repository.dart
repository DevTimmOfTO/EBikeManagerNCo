import 'package:drift/drift.dart';
import 'package:ebikemanager/core/database/app_database.dart';
import 'package:ebikemanager/core/domain/entities/app_settings.dart';
import 'package:ebikemanager/core/domain/repositories/app_settings_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'drift_app_settings_repository.g.dart';

extension on AppSettingsRow {
  AppSettings toDomain() => AppSettings(
    updatedAt: updatedAt,
    unitSystem: unitSystem,
    themePreference: themePreference,
    healthSyncEnabled: healthSyncEnabled,
    showBicycleShopsLayer: showBicycleShopsLayer,
    showRepairStationsLayer: showRepairStationsLayer,
    showChargingStationsLayer: showChargingStationsLayer,
    showCyclewaysLayer: showCyclewaysLayer,
    displayName: displayName,
    avatarPath: avatarPath,
    defaultBikeId: defaultBikeId,
  );
}

extension on AppSettings {
  AppSettingsTableCompanion toCompanion() => AppSettingsTableCompanion(
    updatedAt: Value(updatedAt),
    unitSystem: Value(unitSystem),
    themePreference: Value(themePreference),
    healthSyncEnabled: Value(healthSyncEnabled),
    showBicycleShopsLayer: Value(showBicycleShopsLayer),
    showRepairStationsLayer: Value(showRepairStationsLayer),
    showChargingStationsLayer: Value(showChargingStationsLayer),
    showCyclewaysLayer: Value(showCyclewaysLayer),
    displayName: Value(displayName),
    avatarPath: Value(avatarPath),
    defaultBikeId: Value(defaultBikeId),
  );
}

class DriftAppSettingsRepository implements AppSettingsRepository {
  DriftAppSettingsRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<AppSettings> watchSettings() =>
      _db.appSettingsDao.watchSettings().map((row) => row.toDomain());

  @override
  Future<void> updateSettings(AppSettings settings) =>
      _db.appSettingsDao.updateSettings(settings.toCompanion());
}

@riverpod
AppSettingsRepository appSettingsRepository(Ref ref) =>
    DriftAppSettingsRepository(ref.watch(appDatabaseProvider));
