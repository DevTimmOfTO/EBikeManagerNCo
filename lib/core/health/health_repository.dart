import 'package:ebikemanager/core/domain/entities/trip.dart';

/// Abstraction over the platform health store (Health Connect on Android).
///
/// Kept as a clean interface — even though this app is Android-only — so
/// repository consumers and tests don't depend on the `health` package
/// directly.
abstract class HealthRepository {
  Future<bool> isHealthConnectAvailable();

  Future<void> promptInstallHealthConnect();

  Future<bool> hasPermissions();

  Future<bool> requestAuthorization();

  /// Fetches cycling workout sessions recorded between [start] and [end] as
  /// unassigned [Trip]s (`bikeId` left `null`; the caller decides which bike,
  /// if any, to attach) with `source: TripSource.healthConnect` and
  /// `healthConnectRecordId` set for dedup against already-imported trips.
  Future<List<Trip>> fetchCyclingTrips({
    required DateTime start,
    required DateTime end,
  });
}
