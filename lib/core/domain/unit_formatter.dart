import 'package:ebikemanager/core/domain/app_settings_providers.dart';
import 'package:ebikemanager/core/domain/enums.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'unit_formatter.g.dart';

const _metersPerMile = 1609.344;
const _kmhToMph = 0.621371;
const _metersToFeet = 3.28084;

/// Formats distance/speed/elevation for display, converting to imperial units
/// when [system] is [UnitSystem.imperial]. Duration, calories, and heart
/// rate are unit-system-independent and aren't handled here.
class UnitFormatter {
  const UnitFormatter(this.system);

  final UnitSystem system;

  String distance(double? meters) {
    if (meters == null) return '—';
    return system == UnitSystem.imperial
        ? '${(meters / _metersPerMile).toStringAsFixed(1)} mi'
        : '${(meters / 1000).toStringAsFixed(1)} km';
  }

  String speed(double? kmh) {
    if (kmh == null) return '—';
    return system == UnitSystem.imperial
        ? '${(kmh * _kmhToMph).toStringAsFixed(1)} mph'
        : '${kmh.toStringAsFixed(1)} km/h';
  }

  String elevation(double? meters) {
    if (meters == null) return '—';
    return system == UnitSystem.imperial
        ? '${(meters * _metersToFeet).toStringAsFixed(0)} ft'
        : '${meters.toStringAsFixed(0)} m';
  }
}

@riverpod
UnitFormatter unitFormatter(Ref ref) {
  final unitSystem =
      ref.watch(appSettingsProvider).value?.unitSystem ?? UnitSystem.metric;
  return UnitFormatter(unitSystem);
}
