import 'dart:convert';
import 'dart:io';

import 'package:ebikemanager/core/database/repositories/drift_app_settings_repository.dart';
import 'package:ebikemanager/core/database/repositories/drift_data_portability_repository.dart';
import 'package:ebikemanager/core/domain/app_settings_providers.dart';
import 'package:ebikemanager/core/domain/entities/app_data_bundle.dart';
import 'package:ebikemanager/core/domain/entities/app_settings.dart';
import 'package:ebikemanager/core/domain/enums.dart';
import 'package:ebikemanager/core/files/file_picker_service.dart';
import 'package:ebikemanager/core/files/share_service.dart';
import 'package:ebikemanager/core/permissions/permission_status_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(appSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: settingsAsync.when(
        data: (settings) => ListView(
          children: [
            const _SectionHeader('Preferences'),
            _PreferencesSection(settings: settings),
            const Divider(),
            const _SectionHeader('Data'),
            const _DataSection(),
            const Divider(),
            const _SectionHeader('Permissions'),
            const _PermissionsSection(),
            const Divider(),
            const _SectionHeader('About'),
            const _AboutSection(),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            Center(child: Text('Failed to load settings: $error')),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _PreferencesSection extends ConsumerWidget {
  const _PreferencesSection({required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> update(AppSettings Function(AppSettings) transform) =>
        ref
            .read(appSettingsRepositoryProvider)
            .updateSettings(
              transform(settings).copyWith(updatedAt: DateTime.now()),
            );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Units'),
          const SizedBox(height: 4),
          SegmentedButton<UnitSystem>(
            segments: const [
              ButtonSegment(value: UnitSystem.metric, label: Text('Metric')),
              ButtonSegment(
                value: UnitSystem.imperial,
                label: Text('Imperial'),
              ),
            ],
            selected: {settings.unitSystem},
            onSelectionChanged: (selection) =>
                update((s) => s.copyWith(unitSystem: selection.first)),
          ),
          const SizedBox(height: 16),
          const Text('Theme'),
          const SizedBox(height: 4),
          SegmentedButton<ThemePreference>(
            segments: const [
              ButtonSegment(
                value: ThemePreference.system,
                label: Text('System'),
              ),
              ButtonSegment(
                value: ThemePreference.light,
                label: Text('Light'),
              ),
              ButtonSegment(value: ThemePreference.dark, label: Text('Dark')),
            ],
            selected: {settings.themePreference},
            onSelectionChanged: (selection) =>
                update((s) => s.copyWith(themePreference: selection.first)),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Health Connect sync'),
            subtitle: const Text('Show the sync button on the History tab'),
            value: settings.healthSyncEnabled,
            onChanged: (value) =>
                update((s) => s.copyWith(healthSyncEnabled: value)),
          ),
        ],
      ),
    );
  }
}

class _DataSection extends ConsumerWidget {
  const _DataSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.file_upload_outlined),
          title: const Text('Export data'),
          subtitle: const Text(
            'Save your bikes, trips, and battery history as JSON',
          ),
          onTap: () => _exportData(context, ref),
        ),
        ListTile(
          leading: const Icon(Icons.file_download_outlined),
          title: const Text('Import data'),
          subtitle: const Text(
            'Restore or merge from a previously exported file',
          ),
          onTap: () => _importData(context, ref),
        ),
        ListTile(
          leading: Icon(
            Icons.delete_forever_outlined,
            color: Theme.of(context).colorScheme.error,
          ),
          title: Text(
            'Clear all data',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          subtitle: const Text(
            'Permanently delete every bike, trip, and battery entry',
          ),
          onTap: () => _clearAllData(context, ref),
        ),
      ],
    );
  }

  Future<void> _exportData(BuildContext context, WidgetRef ref) async {
    final bundle = await ref
        .read(dataPortabilityRepositoryProvider)
        .exportAll();
    final json = const JsonEncoder.withIndent('  ').convert(bundle.toJson());
    await ref
        .read(shareServiceProvider)
        .shareJsonFile(
          json,
          fileName:
              'ebikemanager-export-'
              '${DateTime.now().millisecondsSinceEpoch}.json',
          subject: 'EBike Manager data export',
        );
  }

  Future<void> _importData(BuildContext context, WidgetRef ref) async {
    final path = await ref.read(filePickerServiceProvider).pickJsonFilePath();
    if (path == null) return;

    final AppDataBundle bundle;
    try {
      final content = await File(path).readAsString();
      bundle = AppDataBundle.fromJson(
        jsonDecode(content) as Map<String, dynamic>,
      );
    } on Exception catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "That file isn't a valid EBike Manager export: $error",
            ),
          ),
        );
      }
      return;
    }

    if (!context.mounted) return;
    final overwrite = await _askOverwrite(context);
    if (overwrite == null) return;

    await ref
        .read(dataPortabilityRepositoryProvider)
        .importAll(bundle, overwrite: overwrite);
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Import complete')));
    }
  }

  Future<bool?> _askOverwrite(BuildContext context) => showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Import data'),
      content: const Text(
        "Merge keeps what's already on this device and adds anything new "
        "from the file. Overwrite replaces all of it with the file's "
        'contents.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Merge'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Overwrite'),
        ),
      ],
    ),
  );

  Future<void> _clearAllData(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear all data?'),
        content: const Text(
          'This permanently deletes every bike, trip, battery-history '
          'entry, and parking pin. Your settings (name, theme, units) are '
          "kept. This can't be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear everything'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref.read(dataPortabilityRepositoryProvider).clearAllData();
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('All data cleared')));
    }
  }
}

class _PermissionsSection extends ConsumerStatefulWidget {
  const _PermissionsSection();

  @override
  ConsumerState<_PermissionsSection> createState() =>
      _PermissionsSectionState();
}

class _PermissionsSectionState extends ConsumerState<_PermissionsSection> {
  late Future<AppPermissionStatus> _locationStatus;
  late Future<AppPermissionStatus> _cameraStatus;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    final service = ref.read(permissionStatusServiceProvider);
    _locationStatus = service.locationStatus();
    _cameraStatus = service.cameraStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _PermissionRow(
          label: 'Location',
          statusFuture: _locationStatus,
          onRefresh: () => setState(_refresh),
        ),
        _PermissionRow(
          label: 'Camera',
          statusFuture: _cameraStatus,
          onRefresh: () => setState(_refresh),
        ),
      ],
    );
  }
}

class _PermissionRow extends ConsumerWidget {
  const _PermissionRow({
    required this.label,
    required this.statusFuture,
    required this.onRefresh,
  });

  final String label;
  final Future<AppPermissionStatus> statusFuture;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<AppPermissionStatus>(
      future: statusFuture,
      builder: (context, snapshot) {
        final status = snapshot.data;
        return ListTile(
          leading: const Icon(Icons.verified_user_outlined),
          title: Text(label),
          subtitle: Text(_describe(status)),
          trailing: TextButton(
            onPressed: () async {
              await ref.read(permissionStatusServiceProvider).openSettings();
              onRefresh();
            },
            child: const Text('Open settings'),
          ),
        );
      },
    );
  }

  String _describe(AppPermissionStatus? status) => switch (status) {
    null => 'Checking…',
    AppPermissionStatus.granted => 'Granted',
    AppPermissionStatus.denied => 'Not granted',
    AppPermissionStatus.permanentlyDenied =>
      'Denied — enable it in the OS settings',
    AppPermissionStatus.restricted => 'Restricted',
  };
}

class _AboutSection extends StatelessWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'EBike Manager is local-only: all your data stays on this '
            "device. There's no account, no cloud sync, and nothing is "
            'shared with anyone.',
          ),
        ),
        ListTile(
          leading: const Icon(Icons.description_outlined),
          title: const Text('Open-source licenses'),
          onTap: () => showLicensePage(
            context: context,
            applicationName: 'EBike Manager',
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Map data © OpenStreetMap contributors, queried live via the '
            'Overpass API. Trip and workout data, when synced, comes from '
            'Android Health Connect.',
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
        ),
      ],
    );
  }
}
