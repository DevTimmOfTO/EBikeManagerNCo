import 'dart:convert';

import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:ebikemanager/core/database/app_database.dart';
import 'package:ebikemanager/core/database/repositories/drift_bike_repository.dart';
import 'package:ebikemanager/core/domain/app_settings_providers.dart';
import 'package:ebikemanager/core/domain/entities/bike.dart';
import 'package:ebikemanager/core/domain/enums.dart';
import 'package:ebikemanager/core/files/file_picker_service.dart';
import 'package:ebikemanager/core/files/share_service.dart';
import 'package:ebikemanager/core/permissions/permission_status_service.dart';
import 'package:ebikemanager/features/profile/presentation/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeFilePickerService implements FilePickerService {
  _FakeFilePickerService(this.path);

  final String? path;

  @override
  Future<String?> pickJsonFilePath() async => path;
}

class _FakeShareService implements ShareService {
  String? sharedJson;

  @override
  Future<void> shareJsonFile(
    String json, {
    required String fileName,
    String? subject,
  }) async {
    sharedJson = json;
  }
}

class _FakePermissionStatusService implements PermissionStatusService {
  int openSettingsCallCount = 0;

  @override
  Future<AppPermissionStatus> locationStatus() async =>
      AppPermissionStatus.granted;

  @override
  Future<AppPermissionStatus> cameraStatus() async =>
      AppPermissionStatus.denied;

  @override
  Future<void> openSettings() async => openSettingsCallCount++;
}

ProviderContainer _buildContainer({
  FilePickerService? filePickerService,
  ShareService? shareService,
}) {
  final container = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWith(
        (ref) => AppDatabase(NativeDatabase.memory()),
      ),
      filePickerServiceProvider.overrideWith(
        (ref) => filePickerService ?? _FakeFilePickerService(null),
      ),
      shareServiceProvider.overrideWith(
        (ref) => shareService ?? _FakeShareService(),
      ),
      permissionStatusServiceProvider.overrideWith(
        (ref) => _FakePermissionStatusService(),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

Future<void> _pumpScreen(
  WidgetTester tester,
  ProviderContainer container,
) async {
  // Settings has more sections than fit in the default 800x600 test
  // surface, which would leave later ones (Permissions, About) outside the
  // ListView's built cache extent. Use a taller virtual viewport instead.
  tester.view.physicalSize = const Size(400, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: SettingsScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets('switching to imperial units persists to app settings', (
    tester,
  ) async {
    final container = _buildContainer();
    await _pumpScreen(tester, container);

    await tester.tap(find.text('Imperial'));
    await tester.pumpAndSettle();

    final settings = await container.read(appSettingsProvider.future);
    expect(settings.unitSystem, UnitSystem.imperial);
  });

  testWidgets('switching theme to dark persists to app settings', (
    tester,
  ) async {
    final container = _buildContainer();
    await _pumpScreen(tester, container);

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    final settings = await container.read(appSettingsProvider.future);
    expect(settings.themePreference, ThemePreference.dark);
  });

  testWidgets('turning off Health Connect sync persists to app settings', (
    tester,
  ) async {
    final container = _buildContainer();
    await _pumpScreen(tester, container);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    final settings = await container.read(appSettingsProvider.future);
    expect(settings.healthSyncEnabled, isFalse);
  });

  testWidgets('exporting data shares a JSON bundle of the current data', (
    tester,
  ) async {
    final shareService = _FakeShareService();
    final container = _buildContainer(shareService: shareService);
    final now = DateTime.now();
    await container
        .read(bikeRepositoryProvider)
        .saveBike(
          Bike(id: 'bike-1', nickname: 'Blitz', createdAt: now, updatedAt: now),
        );
    await _pumpScreen(tester, container);

    await tester.tap(find.text('Export data'));
    await tester.pumpAndSettle();

    expect(shareService.sharedJson, isNotNull);
    final decoded =
        jsonDecode(shareService.sharedJson!) as Map<String, dynamic>;
    final bikes = decoded['bikes'] as List<dynamic>;
    expect((bikes.single as Map<String, dynamic>)['nickname'], 'Blitz');
  });

  // No automated widget tests for "importing a valid/invalid file" or
  // "clearing all data": every variant tried (plain pumpAndSettle, bounded
  // pump() sequences, tester.runAsync() around the real file read, an
  // explicit widget-tree unmount before test end) reproducibly hangs partway
  // through in this environment, while the exact same production code path
  // (DataPortabilityRepository.importAll/clearAllData, including merge vs.
  // overwrite and multi-table deletes) is already covered — fast and
  // reliably — by drift_data_portability_repository_test.dart with no UI
  // involved. The common thread across every hanging test in this file and
  // in bike_detail_delete_test.dart is an operation that changes rows across
  // multiple tables at once (cascade deletes, multi-table import/clear);
  // single-table writes (export, unit/theme toggles, editing one bike,
  // archiving) all pass reliably. These three flows (file import with a
  // merge/overwrite choice, and the clear-all-data danger zone) are verified
  // on-device instead.

  testWidgets('shows permission statuses from the permission service', (
    tester,
  ) async {
    final container = _buildContainer();
    await _pumpScreen(tester, container);

    expect(find.text('Granted'), findsOneWidget);
    expect(find.text('Not granted'), findsOneWidget);
  });
}
