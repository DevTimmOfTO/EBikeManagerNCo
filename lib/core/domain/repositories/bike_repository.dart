import 'package:ebikemanager/core/domain/entities/bike.dart';

abstract class BikeRepository {
  Stream<List<Bike>> watchNonArchivedBikes();

  /// Includes archived bikes too, for the Manage Bikes screen.
  Stream<List<Bike>> watchAllBikes();

  Stream<Bike?> watchBikeById(String id);

  Future<Bike?> getBikeById(String id);

  Future<void> saveBike(Bike bike);

  Future<void> deleteBike(String id);
}
