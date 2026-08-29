import 'dart:convert';

import 'package:ebikemanager/features/navigation/data/overpass_api_repository.dart';
import 'package:ebikemanager/features/navigation/domain/map_bounds.dart';
import 'package:ebikemanager/features/navigation/domain/point_of_interest.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

class _MockClient extends Mock implements http.Client {}

void main() {
  late _MockClient client;
  late OverpassApiRepository repository;

  setUpAll(() {
    registerFallbackValue(Uri());
  });

  setUp(() {
    client = _MockClient();
    repository = OverpassApiRepository(client: client);
  });

  const bounds = MapBounds(south: 51, west: -1, north: 52, east: 0);

  void mockResponse(int statusCode, Object body) {
    when(
      () => client.post(
        any(),
        headers: any(named: 'headers'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((_) async => http.Response(jsonEncode(body), statusCode));
  }

  test('parses nodes into the right POI categories', () async {
    mockResponse(200, {
      'elements': [
        {
          'type': 'node',
          'id': 1,
          'lat': 51.5,
          'lon': -0.1,
          'tags': {'shop': 'bicycle', 'name': 'Bike Shop'},
        },
        {
          'type': 'node',
          'id': 2,
          'lat': 51.6,
          'lon': -0.2,
          'tags': {'amenity': 'bicycle_repair_station'},
        },
        {
          'type': 'node',
          'id': 3,
          'lat': 51.7,
          'lon': -0.3,
          'tags': {'amenity': 'charging_station'},
        },
        {
          'type': 'node',
          'id': 4,
          'lat': 51.8,
          'lon': -0.4,
          'tags': {'amenity': 'restaurant'},
        },
      ],
    });

    final result = await repository.queryPois(bounds);

    expect(result.pointsOfInterest, hasLength(3));
    expect(
      result.pointsOfInterest.map((p) => p.category),
      containsAll(<PoiCategory>[
        PoiCategory.bicycleShop,
        PoiCategory.repairStation,
        PoiCategory.chargingStation,
      ]),
    );
    expect(result.pointsOfInterest.first.name, 'Bike Shop');
    expect(result.pointsOfInterest.first.id, 'node/1');
  });

  test('parses cycleway ways using their geometry', () async {
    mockResponse(200, {
      'elements': [
        {
          'type': 'way',
          'id': 42,
          'tags': {'highway': 'cycleway'},
          'geometry': [
            {'lat': 51.5, 'lon': -0.1},
            {'lat': 51.51, 'lon': -0.11},
          ],
        },
        {
          'type': 'way',
          'id': 43,
          'tags': {'highway': 'residential'},
          'geometry': [
            {'lat': 51.5, 'lon': -0.1},
          ],
        },
      ],
    });

    final result = await repository.queryPois(bounds);

    expect(result.cycleways, hasLength(1));
    expect(result.cycleways.single.id, 'way/42');
    expect(result.cycleways.single.points, hasLength(2));
    expect(result.cycleways.single.points.first.lat, 51.5);
  });

  test('throws OverpassRequestException on a non-200 response', () async {
    mockResponse(429, 'rate limited');

    expect(
      () => repository.queryPois(bounds),
      throwsA(isA<OverpassRequestException>()),
    );
  });
}
