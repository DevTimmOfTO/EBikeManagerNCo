import 'dart:convert';

import 'package:ebikemanager/features/navigation/domain/cycleway_segment.dart';
import 'package:ebikemanager/features/navigation/domain/map_bounds.dart';
import 'package:ebikemanager/features/navigation/domain/overpass_repository.dart';
import 'package:ebikemanager/features/navigation/domain/point_of_interest.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'overpass_api_repository.g.dart';

/// The public Overpass instance by default. Override at build time with
/// `--dart-define=OVERPASS_ENDPOINT=https://your-self-hosted-instance/api/interpreter`
/// once a self-hosted instance is available, per the plan's fair-use note —
/// no code change needed to switch.
const String overpassEndpoint = String.fromEnvironment(
  'OVERPASS_ENDPOINT',
  defaultValue: 'https://overpass-api.de/api/interpreter',
);

const _userAgent =
    'EBikeManagerNCo/1.0 (Android; local-only e-bike companion app)';
const _requestTimeout = Duration(seconds: 25);

class OverpassApiRepository implements OverpassRepository {
  OverpassApiRepository({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  @override
  Future<OverpassQueryResult> queryPois(MapBounds bounds) async {
    final query = _buildQuery(bounds);
    final response = await _client
        .post(
          Uri.parse(overpassEndpoint),
          headers: const {'User-Agent': _userAgent},
          body: {'data': query},
        )
        .timeout(_requestTimeout);

    if (response.statusCode != 200) {
      throw OverpassRequestException(response.statusCode, response.body);
    }

    final elements =
        (jsonDecode(response.body) as Map<String, dynamic>)['elements'] as List;
    final pois = <PointOfInterest>[];
    final cycleways = <CyclewaySegment>[];

    for (final raw in elements) {
      final element = raw as Map<String, dynamic>;
      final tags = (element['tags'] as Map<String, dynamic>?) ?? const {};
      final type = element['type'] as String;

      if (type == 'node') {
        final category = _categoryForTags(tags);
        if (category != null) {
          pois.add(
            PointOfInterest(
              id: '${element['type']}/${element['id']}',
              category: category,
              lat: (element['lat'] as num).toDouble(),
              lng: (element['lon'] as num).toDouble(),
              name: tags['name'] as String?,
            ),
          );
        }
      } else if (type == 'way' && tags['highway'] == 'cycleway') {
        final geometry = element['geometry'] as List?;
        if (geometry != null) {
          cycleways.add(
            CyclewaySegment(
              id: '${element['type']}/${element['id']}',
              points: geometry
                  .cast<Map<String, dynamic>>()
                  .map(
                    (point) => GeoPoint(
                      lat: (point['lat'] as num).toDouble(),
                      lng: (point['lon'] as num).toDouble(),
                    ),
                  )
                  .toList(),
            ),
          );
        }
      }
    }

    return OverpassQueryResult(pointsOfInterest: pois, cycleways: cycleways);
  }

  static PoiCategory? _categoryForTags(Map<String, dynamic> tags) {
    if (tags['shop'] == 'bicycle') return PoiCategory.bicycleShop;
    if (tags['amenity'] == 'bicycle_repair_station') {
      return PoiCategory.repairStation;
    }
    if (tags['amenity'] == 'charging_station') {
      return PoiCategory.chargingStation;
    }
    return null;
  }

  static String _buildQuery(MapBounds bounds) {
    final bbox =
        '${bounds.south},${bounds.west},${bounds.north},${bounds.east}';
    return '[out:json][timeout:25];'
        '('
        'node["shop"="bicycle"]($bbox);'
        'node["amenity"="bicycle_repair_station"]($bbox);'
        'node["amenity"="charging_station"]($bbox);'
        'way["highway"="cycleway"]($bbox);'
        ');'
        'out geom;';
  }
}

class OverpassRequestException implements Exception {
  OverpassRequestException(this.statusCode, this.body);

  final int statusCode;
  final String body;

  @override
  String toString() => 'OverpassRequestException($statusCode)';
}

@riverpod
OverpassRepository overpassRepository(Ref ref) => OverpassApiRepository();
