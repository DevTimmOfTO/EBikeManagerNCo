import 'dart:io';

import 'package:ebikemanager/core/domain/bike_selection_providers.dart';
import 'package:ebikemanager/core/domain/entities/bike.dart';
import 'package:ebikemanager/core/domain/entities/trip.dart';
import 'package:ebikemanager/core/domain/unit_formatter.dart';
import 'package:ebikemanager/features/dashboard/domain/dashboard_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bikesAsync = ref.watch(nonArchivedBikesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: bikesAsync.when(
        data: (bikes) {
          if (bikes.isEmpty) return const _EmptyState();

          final selectedId = ref.watch(selectedBikeIdProvider);
          final selectedBike = bikes.firstWhere(
            (bike) => bike.id == selectedId,
            orElse: () => bikes.first,
          );
          return _DashboardContent(bikes: bikes, selectedBike: selectedBike);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            Center(child: Text('Failed to load bikes: $error')),
      ),
    );
  }
}

class _DashboardContent extends ConsumerWidget {
  const _DashboardContent({required this.bikes, required this.selectedBike});

  final List<Bike> bikes;
  final Bike selectedBike;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batteryAsync = ref.watch(
      latestBatteryEntryForBikeProvider(selectedBike.id),
    );
    final tripAsync = ref.watch(latestTripForBikeProvider(selectedBike.id));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (bikes.length > 1) ...[
          _BikeSelector(bikes: bikes, selectedBikeId: selectedBike.id),
          const SizedBox(height: 16),
        ],
        _BikeSummaryCard(bike: selectedBike),
        const SizedBox(height: 16),
        _QuickStatsRow(
          batteryHealthPct: batteryAsync.value?.estimatedHealthPct,
          lastTrip: tripAsync.value,
          purchaseDate: selectedBike.purchaseDate,
        ),
        const SizedBox(height: 16),
        _QuickLinksRow(bikeId: selectedBike.id),
      ],
    );
  }
}

class _BikeSelector extends ConsumerWidget {
  const _BikeSelector({required this.bikes, required this.selectedBikeId});

  final List<Bike> bikes;
  final String selectedBikeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DropdownButtonFormField<String>(
      initialValue: selectedBikeId,
      decoration: const InputDecoration(labelText: 'Bike'),
      items: [
        for (final bike in bikes)
          DropdownMenuItem(value: bike.id, child: Text(bike.nickname)),
      ],
      onChanged: (bikeId) {
        if (bikeId != null) {
          ref.read(selectedBikeIdProvider.notifier).bikeId = bikeId;
        }
      },
    );
  }
}

class _BikeSummaryCard extends StatelessWidget {
  const _BikeSummaryCard({required this.bike});

  final Bike bike;

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      bike.manufacturer,
      bike.model,
    ].where((part) => part != null && part.isNotEmpty).join(' ');

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          radius: 28,
          backgroundImage: bike.photoPath != null
              ? FileImage(File(bike.photoPath!))
              : null,
          child: bike.photoPath == null ? const Icon(Icons.pedal_bike) : null,
        ),
        title: Text(
          bike.nickname,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        subtitle: subtitle.isEmpty ? null : Text(subtitle),
      ),
    );
  }
}

class _QuickStatsRow extends ConsumerWidget {
  const _QuickStatsRow({
    required this.batteryHealthPct,
    required this.lastTrip,
    required this.purchaseDate,
  });

  final double? batteryHealthPct;
  final Trip? lastTrip;
  final DateTime? purchaseDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daysSincePurchase = purchaseDate == null
        ? null
        : DateTime.now().difference(purchaseDate!).inDays;
    final unitFormatter = ref.watch(unitFormatterProvider);

    return Row(
      children: [
        Expanded(
          child: _StatTile(
            icon: Icons.battery_charging_full,
            label: 'Battery health',
            value: batteryHealthPct == null
                ? '—'
                : '${batteryHealthPct!.toStringAsFixed(0)}%',
          ),
        ),
        Expanded(
          child: _StatTile(
            icon: Icons.route,
            label: 'Last trip',
            value: lastTrip == null
                ? '—'
                : _formatTripSummary(lastTrip!, unitFormatter),
          ),
        ),
        Expanded(
          child: _StatTile(
            icon: Icons.event,
            label: 'Owned for',
            value: daysSincePurchase == null ? '—' : '$daysSincePurchase d',
          ),
        ),
      ],
    );
  }

  static String _formatTripSummary(Trip trip, UnitFormatter unitFormatter) {
    final date = trip.startTime.toLocal();
    final dateLabel =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
    if (trip.distanceMeters == null) return dateLabel;
    return '$dateLabel · ${unitFormatter.distance(trip.distanceMeters)}';
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _QuickLinksRow extends StatelessWidget {
  const _QuickLinksRow({required this.bikeId});

  final String bikeId;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _QuickLinkButton(
          icon: Icons.map_outlined,
          label: 'Navigation',
          onTap: () => context.go('/navigation?bikeId=$bikeId'),
        ),
        _QuickLinkButton(
          icon: Icons.history,
          label: 'History',
          onTap: () => context.go('/history'),
        ),
        _QuickLinkButton(
          icon: Icons.build_outlined,
          label: 'Repair',
          onTap: () => context.go('/repair'),
        ),
      ],
    );
  }
}

class _QuickLinkButton extends StatelessWidget {
  const _QuickLinkButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [Icon(icon), const SizedBox(height: 4), Text(label)],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.pedal_bike,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          const Text('No bikes yet'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.go('/profile/bikes'),
            child: const Text('Add your first bike'),
          ),
        ],
      ),
    );
  }
}
