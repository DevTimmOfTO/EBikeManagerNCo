import 'package:ebikemanager/features/navigation/domain/cycleway_segment.dart';
import 'package:ebikemanager/features/navigation/domain/map_bounds.dart';
import 'package:ebikemanager/features/navigation/domain/point_of_interest.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'overpass_repository.freezed.dart';

@freezed
abstract class OverpassQueryResult with _$OverpassQueryResult {
  const factory OverpassQueryResult({
    required List<PointOfInterest> pointsOfInterest,
    required List<CyclewaySegment> cycleways,
  }) = _OverpassQueryResult;
}

// A single-method abstract class is the same repository-interface pattern
// used by every other repository in this codebase (for DI/mocking), not an
// accidental one-off — a top-level function wouldn't be overridable in tests.
// ignore: one_member_abstracts
abstract class OverpassRepository {
  /// Queries bicycle shops, repair stations, charging stations, and cycleway
  /// geometry within [bounds].
  ///
  /// Throws on network failure, timeout, or a non-200 response — callers are
  /// expected to surface those as an error/offline state rather than retry
  /// silently, to respect the Overpass instance's fair-use policy.
  Future<OverpassQueryResult> queryPois(MapBounds bounds);
}
