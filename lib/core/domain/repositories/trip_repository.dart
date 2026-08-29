import 'package:ebikemanager/core/domain/entities/trip.dart';
import 'package:ebikemanager/core/domain/entities/trip_point.dart';

abstract class TripRepository {
  Stream<List<Trip>> watchTripsForBike(String bikeId);

  Stream<List<Trip>> watchAllTrips();

  Stream<Trip?> watchTripById(String id);

  Stream<Trip?> watchLatestTripForBike(String bikeId);

  Future<Trip?> findByHealthConnectRecordId(String recordId);

  Stream<List<TripPoint>> watchPointsForTrip(String tripId);

  Future<void> saveTrip(Trip trip, {List<TripPoint> points});

  Future<void> deleteTrip(String id);
}
