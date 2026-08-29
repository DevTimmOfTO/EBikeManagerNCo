import 'package:freezed_annotation/freezed_annotation.dart';

part 'point_of_interest.freezed.dart';

enum PoiCategory { bicycleShop, repairStation, chargingStation }

@freezed
abstract class PointOfInterest with _$PointOfInterest {
  const factory PointOfInterest({
    required String id,
    required PoiCategory category,
    required double lat,
    required double lng,
    String? name,
  }) = _PointOfInterest;
}
