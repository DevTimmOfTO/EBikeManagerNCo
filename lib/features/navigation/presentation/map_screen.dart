import 'dart:async';

import 'package:ebikemanager/core/database/repositories/drift_app_settings_repository.dart';
import 'package:ebikemanager/core/database/repositories/drift_parking_location_repository.dart';
import 'package:ebikemanager/core/domain/app_settings_providers.dart';
import 'package:ebikemanager/core/domain/entities/app_settings.dart';
import 'package:ebikemanager/core/domain/entities/parking_location.dart';
import 'package:ebikemanager/features/navigation/domain/cycleway_segment.dart';
import 'package:ebikemanager/features/navigation/domain/map_bounds.dart';
import 'package:ebikemanager/features/navigation/domain/navigation_providers.dart';
import 'package:ebikemanager/features/navigation/domain/overpass_repository.dart';
import 'package:ebikemanager/features/navigation/domain/point_of_interest.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';

const _fallbackCenter = LatLng(51.5, -0.09);

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final _mapController = MapController();
  bool _hasCentered = false;

  String? get _bikeId =>
      GoRouterState.of(context).uri.queryParameters['bikeId'];

  @override
  Widget build(BuildContext context) {
    final positionAsync = ref.watch(currentPositionProvider);
    final poiState = ref.watch(mapPoiControllerProvider);
    final settingsAsync = ref.watch(appSettingsProvider);
    final bikeId = _bikeId;
    final parkingAsync = bikeId == null
        ? const AsyncValue<ParkingLocation?>.data(null)
        : ref.watch(activeParkingForBikeProvider(bikeId));

    ref.listen(currentPositionProvider, (previous, next) {
      final position = next.value;
      if (position != null && !_hasCentered) {
        _hasCentered = true;
        _mapController.move(LatLng(position.latitude, position.longitude), 16);
      }
    });
    ref.listen(activeParkingForBikeProvider(bikeId ?? ''), (previous, next) {
      final parking = next.value;
      if (bikeId != null && parking != null && !_hasCentered) {
        _hasCentered = true;
        _mapController.move(LatLng(parking.lat, parking.lng), 16);
      }
    });

    final settings = settingsAsync.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Navigation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.layers_outlined),
            tooltip: 'Map layers',
            onPressed: settings == null
                ? null
                : () => _showLayerPanel(context, settings),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _fallbackCenter,
              initialZoom: 14,
              onPositionChanged: (camera, hasGesture) {
                final bounds = camera.visibleBounds;
                ref
                    .read(mapPoiControllerProvider.notifier)
                    .onMapMoved(
                      MapBounds(
                        south: bounds.south,
                        west: bounds.west,
                        north: bounds.north,
                        east: bounds.east,
                      ),
                    );
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'dev.devtimmofto.ebikemanager',
              ),
              const RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('OpenStreetMap contributors'),
                ],
              ),
              if (settings?.showCyclewaysLayer ?? false)
                PolylineLayer(
                  polylines: [
                    for (final segment
                        in poiState.value?.cycleways ??
                            const <CyclewaySegment>[])
                      Polyline(
                        points: [
                          for (final p in segment.points) LatLng(p.lat, p.lng),
                        ],
                        color: Colors.blueGrey,
                        strokeWidth: 3,
                      ),
                  ],
                ),
              MarkerClusterLayerWidget(
                options: MarkerClusterLayerOptions(
                  maxClusterRadius: 60,
                  size: const Size(36, 36),
                  markers: _visiblePoiMarkers(poiState, settings),
                  builder: (context, markers) => CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text(
                      '${markers.length}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),
              ),
              MarkerLayer(
                markers: [
                  if (positionAsync.value case final position?)
                    Marker(
                      point: LatLng(position.latitude, position.longitude),
                      width: 20,
                      height: 20,
                      child: const _CurrentPositionMarker(),
                    ),
                  if (parkingAsync.value case final parking?)
                    Marker(
                      point: LatLng(parking.lat, parking.lng),
                      width: 40,
                      height: 40,
                      alignment: Alignment.topCenter,
                      child: Icon(
                        Icons.local_parking,
                        color: Colors.orange.shade800,
                        size: 36,
                      ),
                    ),
                ],
              ),
            ],
          ),
          if (positionAsync.hasError)
            _StatusBanner(error: positionAsync.error!),
          if (poiState.hasError)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: _RetryBanner(
                message: "Can't load nearby places.",
                onRetry: () {
                  final bounds = _mapController.camera.visibleBounds;
                  ref
                      .read(mapPoiControllerProvider.notifier)
                      .onMapMoved(
                        MapBounds(
                          south: bounds.south,
                          west: bounds.west,
                          north: bounds.north,
                          east: bounds.east,
                        ),
                      );
                },
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: bikeId == null || positionAsync.value == null
            ? null
            : () =>
                  unawaited(_saveParkedLocation(bikeId, positionAsync.value!)),
        icon: const Icon(Icons.local_parking),
        label: const Text('Save parked location'),
      ),
    );
  }

  List<Marker> _visiblePoiMarkers(
    AsyncValue<OverpassQueryResult> poiState,
    AppSettings? settings,
  ) {
    final pois = poiState.value?.pointsOfInterest ?? const <PointOfInterest>[];
    if (settings == null) return const [];
    return [
      for (final poi in pois)
        if (_isLayerEnabled(poi.category, settings))
          Marker(
            point: LatLng(poi.lat, poi.lng),
            width: 28,
            height: 28,
            child: Icon(
              _iconForCategory(poi.category),
              color: _colorForCategory(poi.category),
            ),
          ),
    ];
  }

  bool _isLayerEnabled(PoiCategory category, AppSettings settings) =>
      switch (category) {
        PoiCategory.bicycleShop => settings.showBicycleShopsLayer,
        PoiCategory.repairStation => settings.showRepairStationsLayer,
        PoiCategory.chargingStation => settings.showChargingStationsLayer,
      };

  static IconData _iconForCategory(PoiCategory category) => switch (category) {
    PoiCategory.bicycleShop => Icons.storefront,
    PoiCategory.repairStation => Icons.build,
    PoiCategory.chargingStation => Icons.ev_station,
  };

  static Color _colorForCategory(PoiCategory category) => switch (category) {
    PoiCategory.bicycleShop => Colors.deepPurple,
    PoiCategory.repairStation => Colors.teal,
    PoiCategory.chargingStation => Colors.green,
  };

  Future<void> _saveParkedLocation(String bikeId, geo.Position position) async {
    await ref
        .read(parkingLocationRepositoryProvider)
        .setParkedLocation(
          ParkingLocation(
            id: const Uuid().v4(),
            bikeId: bikeId,
            lat: position.latitude,
            lng: position.longitude,
            timestamp: DateTime.now(),
          ),
        );
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Parked location saved')));
    }
  }

  void _showLayerPanel(BuildContext context, AppSettings settings) {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        builder: (context) => _LayerTogglePanel(settings: settings),
      ),
    );
  }
}

class _CurrentPositionMarker extends StatelessWidget {
  const _CurrentPositionMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.blue,
        border: Border.all(color: Colors.white, width: 2),
      ),
    );
  }
}

class _LayerTogglePanel extends ConsumerWidget {
  const _LayerTogglePanel({required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> toggle(AppSettings updated) =>
        ref.read(appSettingsRepositoryProvider).updateSettings(updated);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SwitchListTile(
            title: const Text('Bicycle shops'),
            value: settings.showBicycleShopsLayer,
            onChanged: (value) =>
                toggle(settings.copyWith(showBicycleShopsLayer: value)),
          ),
          SwitchListTile(
            title: const Text('Repair stations'),
            value: settings.showRepairStationsLayer,
            onChanged: (value) =>
                toggle(settings.copyWith(showRepairStationsLayer: value)),
          ),
          SwitchListTile(
            title: const Text('Charging stations'),
            value: settings.showChargingStationsLayer,
            onChanged: (value) =>
                toggle(settings.copyWith(showChargingStationsLayer: value)),
          ),
          SwitchListTile(
            title: const Text('Cycleways'),
            value: settings.showCyclewaysLayer,
            onChanged: (value) =>
                toggle(settings.copyWith(showCyclewaysLayer: value)),
          ),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final message = switch (error) {
      LocationServiceDisabledError() =>
        'Turn on location services to see your position.',
      LocationPermissionDeniedException(permanently: true) =>
        'Location permission denied. Enable it in system settings.',
      LocationPermissionDeniedException() => 'Location permission denied.',
      _ => "Can't get your location.",
    };

    return Positioned(
      top: 8,
      left: 16,
      right: 16,
      child: Material(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(
                Icons.location_off,
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
              ),
              if (error is LocationPermissionDeniedException &&
                  (error as LocationPermissionDeniedException).permanently)
                const TextButton(
                  onPressed: geo.Geolocator.openAppSettings,
                  child: Text('Settings'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RetryBanner extends StatelessWidget {
  const _RetryBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.errorContainer,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
            ),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
