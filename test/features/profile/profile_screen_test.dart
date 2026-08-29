import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:ebikemanager/core/app_info/app_info_service.dart';
import 'package:ebikemanager/core/database/app_database.dart';
import 'package:ebikemanager/core/domain/app_settings_providers.dart';
import 'package:ebikemanager/core/files/image_picker_service.dart';
import 'package:ebikemanager/core/files/local_image_store.dart';
import 'package:ebikemanager/features/profile/presentation/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

class _FakeAppInfoService implements AppInfoService {
  @override
  Future<String> versionLabel() async => '9.9.9 (42)';
}

class _FakeImagePickerService implements ImagePickerService {
  _FakeImagePickerService({this.galleryResult});

  final XFile? galleryResult;

  @override
  Future<XFile?> pickFromCamera() async => null;

  @override
  Future<XFile?> pickFromGallery() async => galleryResult;
}

class _FakeLocalImageStore implements LocalImageStore {
  final List<String> deleted = [];

  @override
  Future<String> save(
    XFile source, {
    required String category,
    String? previousPath,
  }) async {
    if (previousPath != null) deleted.add(previousPath);
    return '/fake/$category/avatar.jpg';
  }

  @override
  Future<void> delete(String path) async => deleted.add(path);
}

ProviderContainer _buildContainer({ImagePickerService? imagePickerService}) {
  final container = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWith(
        (ref) => AppDatabase(NativeDatabase.memory()),
      ),
      appInfoServiceProvider.overrideWith((ref) => _FakeAppInfoService()),
      imagePickerServiceProvider.overrideWith(
        (ref) => imagePickerService ?? _FakeImagePickerService(),
      ),
      localImageStoreProvider.overrideWith((ref) => _FakeLocalImageStore()),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

Future<void> _pumpScreen(
  WidgetTester tester,
  ProviderContainer container,
) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: ProfileScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets('shows a placeholder name and the app version by default', (
    tester,
  ) async {
    final container = _buildContainer();
    await _pumpScreen(tester, container);

    expect(find.text('Add your name'), findsOneWidget);
    expect(find.text('Version 9.9.9 (42)'), findsOneWidget);
  });

  testWidgets('editing the display name persists it to app settings', (
    tester,
  ) async {
    final container = _buildContainer();
    await _pumpScreen(tester, container);

    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Timm');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(find.text('Timm'), findsOneWidget);
    expect(find.text('Add your name'), findsNothing);
    final settings = await container.read(appSettingsProvider.future);
    expect(settings.displayName, 'Timm');
  });

  testWidgets('picking an avatar saves it through the image store', (
    tester,
  ) async {
    final container = _buildContainer(
      imagePickerService: _FakeImagePickerService(
        galleryResult: XFile('${Directory.systemTemp.path}/avatar.jpg'),
      ),
    );
    await _pumpScreen(tester, container);

    await tester.tap(find.byType(CircleAvatar));
    await tester.pumpAndSettle();

    final settings = await container.read(appSettingsProvider.future);
    expect(settings.avatarPath, '/fake/avatar/avatar.jpg');
  });
}
