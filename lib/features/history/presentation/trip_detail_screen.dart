import 'package:ebikemanager/core/domain/entities/trip.dart';
import 'package:ebikemanager/core/domain/entities/trip_point.dart';
import 'package:ebikemanager/core/domain/unit_formatter.dart';
import 'package:ebikemanager/features/history/domain/history_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

class TripDetailScreen extends ConsumerWidget {
  const TripDetailScreen({required this.tripId, super.key});

  final String tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripAsync = ref.watch(tripByIdProvider(tripId));

    return Scaffold(
      appBar: AppBar(title: const Text('Trip')),
      body: tripAsync.when(
        data: (trip) {
          if (trip == null) return const Center(child: Text('Trip not found.'));
          return _TripDetailBody(trip: trip);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            Center(child: Text('Failed to load trip: $error')),
      ),
    );
  }
}

class _TripDetailBody extends ConsumerWidget {
  const _TripDetailBody({required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pointsAsync = ref.watch(tripPointsForTripProvider(trip.id));
    final local = trip.startTime.toLocal();
    final datePart =
        '${local.year}-${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
    final timePart =
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
    final dateLabel = '$datePart $timePart';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(dateLabel, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        pointsAsync.when(
          data: (points) {
            if (points.length < 2) return const SizedBox.shrink();
            return SizedBox(height: 220, child: _RoutePreview(points: points));
          },
          loading: () => const SizedBox.shrink(),
          error: (error, stackTrace) => const SizedBox.shrink(),
        ),
        const SizedBox(height: 16),
        _StatsGrid(trip: trip, unitFormatter: ref.watch(unitFormatterProvider)),
      ],
    );
  }
}

class _RoutePreview extends StatelessWidget {
  const _RoutePreview({required this.points});

  final List<TripPoint> points;

  @override
  Widget build(BuildContext context) {
    final latLngs = [for (final p in points) LatLng(p.lat, p.lng)];
    final bounds = LatLngBounds.fromPoints(latLngs);

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: FlutterMap(
        options: MapOptions(
          initialCameraFit: CameraFit.bounds(
            bounds: bounds,
            padding: const EdgeInsets.all(24),
          ),
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.none,
          ),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'dev.devtimmofto.ebikemanager',
          ),
          const RichAttributionWidget(
            attributions: [TextSourceAttribution('OpenStreetMap contributors')],
          ),
          PolylineLayer(
            polylines: [
              Polyline(
                points: latLngs,
                color: Theme.of(context).colorScheme.primary,
                strokeWidth: 4,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.trip, required this.unitFormatter});

  final Trip trip;
  final UnitFormatter unitFormatter;

  @override
  Widget build(BuildContext context) {
    final stats = <(IconData, String, String)>[
      (Icons.route, 'Distance', unitFormatter.distance(trip.distanceMeters)),
      (
        Icons.timer_outlined,
        'Duration',
        trip.durationSeconds == null
            ? '—'
            : '${(trip.durationSeconds! / 60).round()} min',
      ),
      (Icons.speed, 'Avg speed', unitFormatter.speed(trip.avgSpeedKmh)),
      (
        Icons.terrain,
        'Elevation gain',
        unitFormatter.elevation(trip.elevationGainMeters),
      ),
      (
        Icons.local_fire_department_outlined,
        'Calories',
        trip.caloriesKcal == null
            ? '—'
            : '${trip.caloriesKcal!.toStringAsFixed(0)} kcal',
      ),
      (
        Icons.favorite_border,
        'Avg heart rate',
        trip.heartRateAvgBpm == null ? '—' : '${trip.heartRateAvgBpm} bpm',
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.4,
      children: [
        for (final (icon, label, value) in stats)
          Row(
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: Theme.of(context).textTheme.titleMedium),
                  Text(label, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ],
          ),
      ],
    );
  }
}
