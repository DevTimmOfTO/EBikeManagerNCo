import 'package:ebikemanager/core/database/repositories/drift_bike_repository.dart';
import 'package:ebikemanager/core/domain/entities/bike.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'bike_selection_providers.g.dart';

@riverpod
Stream<List<Bike>> nonArchivedBikes(Ref ref) =>
    ref.watch(bikeRepositoryProvider).watchNonArchivedBikes();

/// Includes archived bikes too, for the Manage Bikes screen.
@riverpod
Stream<List<Bike>> allBikes(Ref ref) =>
    ref.watch(bikeRepositoryProvider).watchAllBikes();

@riverpod
Stream<Bike?> bikeById(Ref ref, String bikeId) =>
    ref.watch(bikeRepositoryProvider).watchBikeById(bikeId);

/// Holds the user's explicit bike choice for screens with a multi-bike
/// selector (Dashboard, Navigation). `null` means "no explicit choice yet" —
/// callers fall back to the first non-archived bike.
@riverpod
class SelectedBikeId extends _$SelectedBikeId {
  @override
  String? build() => null;

  String? get bikeId => state;

  set bikeId(String value) => state = value;
}
