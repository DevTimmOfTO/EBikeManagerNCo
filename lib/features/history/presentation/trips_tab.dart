import 'package:ebikemanager/core/domain/entities/trip.dart';
import 'package:ebikemanager/core/domain/unit_formatter.dart';
import 'package:ebikemanager/features/history/domain/history_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

const _monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June', //
  'July', 'August', 'September', 'October', 'November', 'December',
];

class TripsTab extends ConsumerWidget {
  const TripsTab({required this.bikeId, super.key});

  final String bikeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsAsync = ref.watch(filteredTripsForBikeProvider(bikeId));
    final unitFormatter = ref.watch(unitFormatterProvider);

    return tripsAsync.when(
      data: (trips) {
        if (trips.isEmpty) {
          return const Center(child: Text('No trips yet.'));
        }
        final groups = _groupByMonth(trips);
        return ListView.builder(
          itemCount: groups.length,
          itemBuilder: (context, index) {
            final group = groups[index];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Text(
                    group.label,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                for (final trip in group.trips)
                  _TripCard(trip: trip, unitFormatter: unitFormatter),
              ],
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) =>
          Center(child: Text('Failed to load trips: $error')),
    );
  }

  List<_MonthGroup> _groupByMonth(List<Trip> trips) {
    final groups = <String, _MonthGroup>{};
    for (final trip in trips) {
      final local = trip.startTime.toLocal();
      final key = '${local.year}-${local.month}';
      groups.putIfAbsent(
        key,
        () => _MonthGroup('${_monthNames[local.month - 1]} ${local.year}'),
      );
      groups[key]!.trips.add(trip);
    }
    return groups.values.toList();
  }
}

class _MonthGroup {
  _MonthGroup(this.label);

  final String label;
  final List<Trip> trips = [];
}

class _TripCard extends StatelessWidget {
  const _TripCard({required this.trip, required this.unitFormatter});

  final Trip trip;
  final UnitFormatter unitFormatter;

  @override
  Widget build(BuildContext context) {
    final local = trip.startTime.toLocal();
    final dateLabel =
        '${local.year}-${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: const Icon(Icons.pedal_bike),
        title: Text(dateLabel),
        subtitle: Text(
          [
            if (trip.distanceMeters != null)
              unitFormatter.distance(trip.distanceMeters),
            if (trip.durationSeconds != null)
              '${(trip.durationSeconds! / 60).round()} min',
            trip.source.name,
          ].join(' · '),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.go('/history/trip/${trip.id}'),
      ),
    );
  }
}
