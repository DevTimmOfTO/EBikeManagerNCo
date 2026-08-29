import 'package:freezed_annotation/freezed_annotation.dart';

part 'map_bounds.freezed.dart';

@freezed
abstract class MapBounds with _$MapBounds {
  const factory MapBounds({
    required double south,
    required double west,
    required double north,
    required double east,
  }) = _MapBounds;

  const MapBounds._();

  /// Whether [other] is fully contained within this padded bounds — used to
  /// decide whether a cached POI fetch still covers the visible map area.
  bool contains(MapBounds other) =>
      other.south >= south &&
      other.north <= north &&
      other.west >= west &&
      other.east <= east;

  /// This bounds expanded outward by [factor] (e.g. `0.5` = 50% extra margin
  /// on every side), so panning slightly doesn't immediately invalidate the
  /// cached POI fetch.
  MapBounds padded(double factor) {
    final latPad = (north - south) * factor;
    final lngPad = (east - west) * factor;
    return MapBounds(
      south: south - latPad,
      west: west - lngPad,
      north: north + latPad,
      east: east + lngPad,
    );
  }
}
