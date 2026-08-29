import 'dart:async';

import 'package:ebikemanager/core/database/repositories/drift_parking_location_repository.dart';
import 'package:ebikemanager/core/domain/entities/parking_location.dart';
import 'package:ebikemanager/core/logging/app_logger.dart';
import 'package:ebikemanager/features/navigation/data/overpass_api_repository.dart';
import 'package:ebikemanager/features/navigation/domain/map_bounds.dart';
import 'package:ebikemanager/features/navigation/domain/overpass_repository.dart';
import 'package:geolocator/geolocator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'navigation_providers.g.dart';

const _log = AppLogger('MapPoiController');

class LocationPermissionDeniedException implements Exception {
  const LocationPermissionDeniedException({required this.permanently});

  final bool permanently;
}

class LocationServiceDisabledError implements Exception {
  const LocationServiceDisabledError();
}

@riverpod
Stream<Position> currentPosition(Ref ref) async* {
  if (!await Geolocator.isLocationServiceEnabled()) {
    throw const LocationServiceDisabledError();
  }

  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.denied) {
    throw const LocationPermissionDeniedException(permanently: false);
  }
  if (permission == LocationPermission.deniedForever) {
    throw const LocationPermissionDeniedException(permanently: true);
  }

  yield* Geolocator.getPositionStream(
    locationSettings: const LocationSettings(distanceFilter: 5),
  );
}

@riverpod
Stream<ParkingLocation?> activeParkingForBike(Ref ref, String bikeId) => ref
    .watch(parkingLocationRepositoryProvider)
    .watchActiveParkingForBike(bikeId);

@riverpod
class MapPoiController extends _$MapPoiController {
  Timer? _debounce;
  MapBounds? _cachedBounds;

  @override
  AsyncValue<OverpassQueryResult> build() {
    ref.onDispose(() => _debounce?.cancel());
    return const AsyncLoading();
  }

  /// Called whenever the visible map bounds change. Debounces rapid pan/zoom
  /// and skips re-fetching while still within the last (padded) query area,
  /// to avoid hammering the Overpass instance.
  void onMapMoved(MapBounds bounds) {
    final cached = _cachedBounds;
    if (cached != null && cached.contains(bounds)) return;

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 700), () => _fetch(bounds));
  }

  Future<void> _fetch(MapBounds bounds) async {
    state = const AsyncLoading();
    final padded = bounds.padded(0.5);
    final result = await AsyncValue.guard(
      () => ref.read(overpassRepositoryProvider).queryPois(padded),
    );
    if (result case AsyncError(:final error, :final stackTrace)) {
      _log.error('Overpass query failed', error, stackTrace);
    }
    _cachedBounds = result.hasValue ? padded : null;
    state = result;
  }
}
