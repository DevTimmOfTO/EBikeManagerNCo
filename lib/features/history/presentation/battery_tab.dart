import 'package:ebikemanager/core/database/repositories/drift_battery_history_repository.dart';
import 'package:ebikemanager/core/domain/entities/battery_history_entry.dart';
import 'package:ebikemanager/core/domain/enums.dart';
import 'package:ebikemanager/features/history/domain/battery_degradation.dart';
import 'package:ebikemanager/features/history/domain/history_providers.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class BatteryTab extends ConsumerWidget {
  const BatteryTab({required this.bikeId, super.key});

  final String bikeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(batteryHistoryForBikeProvider(bikeId));

    return Scaffold(
      body: entriesAsync.when(
        data: (entries) {
          // Repository orders newest-first; the chart reads left-to-right.
          final chronological = entries.reversed.toList();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (chronological.length >= 2) ...[
                Text(
                  'Battery health',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 200,
                  child: _HealthChart(entries: chronological),
                ),
                const SizedBox(height: 24),
              ],
              Text(
                'Charge log',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (entries.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('No charge history yet.'),
                )
              else
                for (final entry in entries) _ChargeLogTile(entry: entry),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            Center(child: Text('Failed to load battery history: $error')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showLogChargeDialog(context, ref),
        icon: const Icon(Icons.bolt),
        label: const Text('Log a charge'),
      ),
    );
  }

  Future<void> _showLogChargeDialog(BuildContext context, WidgetRef ref) async {
    final entries = await ref.read(
      batteryHistoryForBikeProvider(bikeId).future,
    );
    final lastCycleCount = entries.isEmpty
        ? 0
        : (entries.first.estimatedCycleCount ?? 0);
    final nextCycleCount = lastCycleCount + 1;
    final suggestedHealthPct = estimateHealthPct(nextCycleCount);

    if (!context.mounted) return;
    final healthPct = await showDialog<double>(
      context: context,
      builder: (context) =>
          _LogChargeDialog(suggestedHealthPct: suggestedHealthPct),
    );
    if (healthPct == null) return;

    final now = DateTime.now();
    await ref
        .read(batteryHistoryRepositoryProvider)
        .saveEntry(
          BatteryHistoryEntry(
            id: const Uuid().v4(),
            bikeId: bikeId,
            timestamp: now,
            eventType: BatteryEventType.chargeCycle,
            createdAt: now,
            updatedAt: now,
            estimatedCycleCount: nextCycleCount,
            estimatedHealthPct: healthPct,
          ),
        );
  }
}

class _HealthChart extends StatelessWidget {
  const _HealthChart({required this.entries});

  final List<BatteryHistoryEntry> entries;

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[
      for (final (index, entry) in entries.indexed)
        if (entry.estimatedHealthPct != null)
          FlSpot(index.toDouble(), entry.estimatedHealthPct!),
    ];

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 100,
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (value, meta) => Text('${value.toInt()}%'),
            ),
          ),
          bottomTitles: const AxisTitles(),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }
}

class _ChargeLogTile extends StatelessWidget {
  const _ChargeLogTile({required this.entry});

  final BatteryHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final local = entry.timestamp.toLocal();
    final dateLabel =
        '${local.year}-${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';

    return ListTile(
      leading: const Icon(Icons.battery_charging_full),
      title: Text(dateLabel),
      subtitle: Text(entry.eventType.name),
      trailing: entry.estimatedHealthPct == null
          ? null
          : Text('${entry.estimatedHealthPct!.toStringAsFixed(0)}%'),
    );
  }
}

class _LogChargeDialog extends StatefulWidget {
  const _LogChargeDialog({required this.suggestedHealthPct});

  final double suggestedHealthPct;

  @override
  State<_LogChargeDialog> createState() => _LogChargeDialogState();
}

class _LogChargeDialogState extends State<_LogChargeDialog> {
  late double _healthPct = widget.suggestedHealthPct;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Log a charge'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Estimated battery health'),
          Slider(
            value: _healthPct,
            max: 100,
            divisions: 100,
            label: '${_healthPct.toStringAsFixed(0)}%',
            onChanged: (value) => setState(() => _healthPct = value),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_healthPct),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
