import 'package:ebikemanager/core/domain/enums.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'trip.freezed.dart';
part 'trip.g.dart';

@freezed
abstract class Trip with _$Trip {
  const factory Trip({
    required String id,
    required DateTime startTime,
    required TripSource source,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? bikeId,
    DateTime? endTime,
    double? distanceMeters,
    int? durationSeconds,
    double? avgSpeedKmh,
    double? elevationGainMeters,
    double? caloriesKcal,
    int? activeMinutes,
    int? heartRateAvgBpm,
    String? healthConnectRecordId,
  }) = _Trip;

  factory Trip.fromJson(Map<String, Object?> json) => _$TripFromJson(json);
}
