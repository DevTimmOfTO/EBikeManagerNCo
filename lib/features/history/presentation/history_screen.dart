import 'package:ebikemanager/core/domain/app_settings_providers.dart';
import 'package:ebikemanager/core/domain/bike_selection_providers.dart';
import 'package:ebikemanager/core/domain/entities/bike.dart';
import 'package:ebikemanager/core/health/health_connect_repository.dart';
import 'package:ebikemanager/features/history/domain/history_providers.dart';
import 'package:ebikemanager/features/history/presentation/battery_tab.dart';
import 'package:ebikemanager/features/history/presentation/trips_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late final _tabController = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bikesAsync = ref.watch(nonArchivedBikesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Trips'),
            Tab(text: 'Battery'),
          ],
        ),
      ),
      body: bikesAsync.when(
        data: (bikes) {
          if (bikes.isEmpty) {
            return const Center(
              child: Text('Add a bike first to see its history.'),
            );
          }
          final selectedId = ref.watch(selectedBikeIdProvider);
          final selectedBike = bikes.firstWhere(
            (bike) => bike.id == selectedId,
            orElse: () => bikes.first,
          );
          return Column(
            children: [
              _FilterBar(bikes: bikes, selectedBike: selectedBike),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    TripsTab(bikeId: selectedBike.id),
                    BatteryTab(bikeId: selectedBike.id),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            Center(child: Text('Failed to load bikes: $error')),
      ),
    );
  }
}

class _FilterBar extends ConsumerWidget {
  const _FilterBar({required this.bikes, required this.selectedBike});

  final List<Bike> bikes;
  final Bike selectedBike;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(historyDateRangeFilterProvider);
    final healthSyncEnabled =
        ref.watch(appSettingsProvider).value?.healthSyncEnabled ?? true;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          if (bikes.length > 1)
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: selectedBike.id,
                decoration: const InputDecoration(
                  labelText: 'Bike',
                  isDense: true,
                ),
                items: [
                  for (final bike in bikes)
                    DropdownMenuItem(
                      value: bike.id,
                      child: Text(bike.nickname),
                    ),
                ],
                onChanged: (bikeId) {
                  if (bikeId != null) {
                    ref.read(selectedBikeIdProvider.notifier).bikeId = bikeId;
                  }
                },
              ),
            )
          else
            Expanded(
              child: Text(
                selectedBike.nickname,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          IconButton(
            tooltip: 'Filter by date range',
            icon: Icon(
              range == null ? Icons.date_range_outlined : Icons.date_range,
            ),
            onPressed: () => _pickDateRange(context, ref),
          ),
          if (range != null)
            IconButton(
              tooltip: 'Clear date filter',
              icon: const Icon(Icons.clear),
              onPressed: () =>
                  ref.read(historyDateRangeFilterProvider.notifier).range =
                      null,
            ),
          if (healthSyncEnabled)
            IconButton(
              tooltip: 'Sync with Health Connect',
              icon: const Icon(Icons.sync),
              onPressed: () =>
                  _syncHealthConnect(context, ref, selectedBike.id),
            ),
        ],
      ),
    );
  }

  Future<void> _pickDateRange(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      initialDateRange: ref.read(historyDateRangeFilterProvider),
    );
    if (picked != null) {
      ref.read(historyDateRangeFilterProvider.notifier).range = picked;
    }
  }

  Future<void> _syncHealthConnect(
    BuildContext context,
    WidgetRef ref,
    String bikeId,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final now = DateTime.now();
    await ref
        .read(healthSyncControllerProvider.notifier)
        .sync(
          bikeId: bikeId,
          start: now.subtract(const Duration(days: 30)),
          end: now,
        );

    final result = ref.read(healthSyncControllerProvider);
    switch (result) {
      case AsyncData(:final value):
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Imported $value new trip${value == 1 ? '' : 's'} '
              'from Health Connect.',
            ),
          ),
        );
      case AsyncError(:final error)
          when error is HealthConnectNotInstalledException:
        messenger.showSnackBar(
          SnackBar(
            content: const Text(
              "Health Connect isn't installed on this device.",
            ),
            action: SnackBarAction(
              label: 'Install',
              onPressed: () => ref
                  .read(healthRepositoryProvider)
                  .promptInstallHealthConnect(),
            ),
          ),
        );
      case AsyncError(:final error)
          when error is HealthConnectPermissionDeniedException:
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Health Connect permission was denied.'),
          ),
        );
      case AsyncError(:final error):
        messenger.showSnackBar(
          SnackBar(content: Text('Health Connect sync failed: $error')),
        );
      default:
        break;
    }
  }
}
