import 'package:freezed_annotation/freezed_annotation.dart';

part 'trip_point.freezed.dart';
part 'trip_point.g.dart';

@freezed
abstract class TripPoint with _$TripPoint {
  const factory TripPoint({
    required String id,
    required String tripId,
    required int sequenceIndex,
    required double lat,
    required double lng,
    double? elevationMeters,
    DateTime? timestamp,
  }) = _TripPoint;

  factory TripPoint.fromJson(Map<String, Object?> json) =>
      _$TripPointFromJson(json);
}
