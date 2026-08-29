import 'package:ebikemanager/core/domain/entities/parking_location.dart';

abstract class ParkingLocationRepository {
  Stream<ParkingLocation?> watchActiveParkingForBike(String bikeId);

  /// Deactivates any existing active pin for `location.bikeId` and stores
  /// [location] as the new active pin.
  Future<void> setParkedLocation(ParkingLocation location);
}
