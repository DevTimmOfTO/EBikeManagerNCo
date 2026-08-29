import 'dart:io';

import 'package:ebikemanager/core/database/repositories/drift_app_settings_repository.dart';
import 'package:ebikemanager/core/domain/app_settings_providers.dart';
import 'package:ebikemanager/core/domain/entities/app_settings.dart';
import 'package:ebikemanager/core/files/image_picker_service.dart';
import 'package:ebikemanager/core/files/local_image_store.dart';
import 'package:ebikemanager/features/profile/domain/profile_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(appSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: settingsAsync.when(
        data: (settings) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _ProfileHeader(settings: settings),
            const SizedBox(height: 24),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.pedal_bike),
                    title: const Text('Manage Bikes'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go('/profile/bikes'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.settings_outlined),
                    title: const Text('Settings'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go('/profile/settings'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const _AboutTile(),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            Center(child: Text('Failed to load profile: $error')),
      ),
    );
  }
}

class _ProfileHeader extends ConsumerWidget {
  const _ProfileHeader({required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => _pickAvatar(ref),
          child: CircleAvatar(
            radius: 32,
            backgroundImage: settings.avatarPath != null
                ? FileImage(File(settings.avatarPath!))
                : null,
            child: settings.avatarPath == null
                ? const Icon(Icons.person, size: 32)
                : null,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            settings.displayName?.isNotEmpty == true
                ? settings.displayName!
                : 'Add your name',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.edit_outlined),
          tooltip: 'Edit name',
          onPressed: () => _editDisplayName(context, ref),
        ),
      ],
    );
  }

  Future<void> _pickAvatar(WidgetRef ref) async {
    final picker = ref.read(imagePickerServiceProvider);
    final picked = await picker.pickFromGallery();
    if (picked == null) return;

    final savedPath = await ref
        .read(localImageStoreProvider)
        .save(picked, category: 'avatar', previousPath: settings.avatarPath);
    await ref
        .read(appSettingsRepositoryProvider)
        .updateSettings(
          settings.copyWith(avatarPath: savedPath, updatedAt: DateTime.now()),
        );
  }

  Future<void> _editDisplayName(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(text: settings.displayName);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Your name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Display name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (name == null) return;

    await ref
        .read(appSettingsRepositoryProvider)
        .updateSettings(
          settings.copyWith(
            displayName: name.isEmpty ? null : name,
            updatedAt: DateTime.now(),
          ),
        );
  }
}

class _AboutTile extends ConsumerWidget {
  const _AboutTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final versionAsync = ref.watch(appVersionLabelProvider);

    return Card(
      child: ListTile(
        leading: const Icon(Icons.info_outline),
        title: const Text('About EBike Manager'),
        subtitle: Text(
          versionAsync.when(
            data: (version) => 'Version $version',
            loading: () => 'Version —',
            error: (error, stackTrace) => 'Version unknown',
          ),
        ),
        onTap: () => showAboutDialog(
          context: context,
          applicationName: 'EBike Manager',
          applicationVersion: versionAsync.value,
          applicationLegalese:
              '© Timm Johannes Göring. Local-only, no account required.',
        ),
      ),
    );
  }
}
