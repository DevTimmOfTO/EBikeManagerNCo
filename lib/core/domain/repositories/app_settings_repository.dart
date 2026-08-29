import 'package:ebikemanager/core/domain/entities/app_settings.dart';

abstract class AppSettingsRepository {
  Stream<AppSettings> watchSettings();

  Future<void> updateSettings(AppSettings settings);
}
