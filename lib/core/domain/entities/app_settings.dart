import 'package:ebikemanager/core/domain/enums.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_settings.freezed.dart';
part 'app_settings.g.dart';

@freezed
abstract class AppSettings with _$AppSettings {
  const factory AppSettings({
    required DateTime updatedAt,
    @Default(UnitSystem.metric) UnitSystem unitSystem,
    @Default(ThemePreference.system) ThemePreference themePreference,
    @Default(true) bool healthSyncEnabled,
    @Default(true) bool showBicycleShopsLayer,
    @Default(true) bool showRepairStationsLayer,
    @Default(true) bool showChargingStationsLayer,
    @Default(true) bool showCyclewaysLayer,
    String? displayName,
    String? avatarPath,
    String? defaultBikeId,
  }) = _AppSettings;

  factory AppSettings.fromJson(Map<String, Object?> json) =>
      _$AppSettingsFromJson(json);
}
