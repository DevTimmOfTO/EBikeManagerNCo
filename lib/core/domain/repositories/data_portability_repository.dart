import 'package:ebikemanager/core/domain/entities/app_data_bundle.dart';

abstract class DataPortabilityRepository {
  Future<AppDataBundle> exportAll();

  /// Imports [bundle]. When [overwrite] is true, all existing bike data is
  /// deleted first; otherwise imported rows are upserted by id alongside
  /// whatever's already there.
  Future<void> importAll(AppDataBundle bundle, {required bool overwrite});

  /// Deletes every bike, trip, trip point, battery-history entry, and
  /// parking pin. Leaves app settings (theme, units, display name) untouched.
  Future<void> clearAllData();
}

const currentAppDataBundleSchemaVersion = 1;
