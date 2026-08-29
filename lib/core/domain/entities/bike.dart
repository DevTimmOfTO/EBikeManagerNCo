import 'package:freezed_annotation/freezed_annotation.dart';

part 'bike.freezed.dart';
part 'bike.g.dart';

@freezed
abstract class Bike with _$Bike {
  const factory Bike({
    required String id,
    required String nickname,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? manufacturer,
    String? model,
    String? colour,
    DateTime? purchaseDate,
    String? adfcCode,
    String? adfcCodePhotoPath,
    String? frameSize,
    String? wheelSize,
    String? motorType,
    int? motorWattage,
    int? batteryCapacityWh,
    DateTime? batteryPurchaseDate,
    int? purchasePriceCents,
    String? photoPath,
    String? notes,
    @Default(false) bool isArchived,
  }) = _Bike;

  factory Bike.fromJson(Map<String, Object?> json) => _$BikeFromJson(json);
}
