import 'package:freezed_annotation/freezed_annotation.dart';

part 'cycleway_segment.freezed.dart';

@freezed
abstract class GeoPoint with _$GeoPoint {
  const factory GeoPoint({required double lat, required double lng}) =
      _GeoPoint;
}

@freezed
abstract class CyclewaySegment with _$CyclewaySegment {
  const factory CyclewaySegment({
    required String id,
    required List<GeoPoint> points,
  }) = _CyclewaySegment;
}
