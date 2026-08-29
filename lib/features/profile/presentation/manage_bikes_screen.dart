import 'dart:io';

import 'package:ebikemanager/core/domain/bike_selection_providers.dart';
import 'package:ebikemanager/core/domain/entities/bike.dart';
import 'package:ebikemanager/features/profile/presentation/bike_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ManageBikesScreen extends ConsumerWidget {
  const ManageBikesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bikesAsync = ref.watch(allBikesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Bikes')),
      body: bikesAsync.when(
        data: (bikes) {
          if (bikes.isEmpty) {
            return const Center(child: Text('No bikes yet.'));
          }
          return ListView(
            children: [for (final bike in bikes) _BikeTile(bike: bike)],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            Center(child: Text('Failed to load bikes: $error')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/profile/bikes/$newBikeRouteId'),
        icon: const Icon(Icons.add),
        label: const Text('Add bike'),
      ),
    );
  }
}

class _BikeTile extends StatelessWidget {
  const _BikeTile({required this.bike});

  final Bike bike;

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      bike.manufacturer,
      bike.model,
    ].where((part) => part != null && part.isNotEmpty).join(' ');

    return ListTile(
      leading: CircleAvatar(
        backgroundImage: bike.photoPath != null
            ? FileImage(File(bike.photoPath!))
            : null,
        child: bike.photoPath == null ? const Icon(Icons.pedal_bike) : null,
      ),
      title: Text(bike.nickname),
      subtitle: subtitle.isEmpty ? null : Text(subtitle),
      trailing: bike.isArchived
          ? const Chip(
              label: Text('Archived'),
              visualDensity: VisualDensity.compact,
            )
          : const Icon(Icons.chevron_right),
      onTap: () => context.go('/profile/bikes/${bike.id}'),
    );
  }
}
