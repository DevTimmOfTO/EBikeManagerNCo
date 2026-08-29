import 'package:freezed_annotation/freezed_annotation.dart';

part 'parking_location.freezed.dart';
part 'parking_location.g.dart';

@freezed
abstract class ParkingLocation with _$ParkingLocation {
  const factory ParkingLocation({
    required String id,
    required String bikeId,
    required double lat,
    required double lng,
    required DateTime timestamp,
    @Default(true) bool isActive,
    String? note,
    String? photoPath,
  }) = _ParkingLocation;

  factory ParkingLocation.fromJson(Map<String, Object?> json) =>
      _$ParkingLocationFromJson(json);
}
