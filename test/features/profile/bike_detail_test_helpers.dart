import 'package:drift/native.dart';
import 'package:ebikemanager/core/database/app_database.dart';
import 'package:ebikemanager/core/domain/entities/bike.dart';
import 'package:ebikemanager/core/files/image_picker_service.dart';
import 'package:ebikemanager/core/files/local_image_store.dart';
import 'package:ebikemanager/features/profile/presentation/bike_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

/// Shared across `bike_detail_*_test.dart` files. Kept as a plain (non-`_test`)
/// file so `flutter test` doesn't try to run it directly — split into these
/// separate test files (rather than one file with multiple `testWidgets`
/// blocks) because running several GoRouter-driven `BikeDetailScreen` tests
/// in sequence inside a single test file/process reproducibly hangs partway
/// through, even though every one of them passes cleanly in isolation. Each
/// file gets its own worker process from `flutter test`, which sidesteps it.
class FakeImagePickerService implements ImagePickerService {
  FakeImagePickerService({this.galleryResult});

  final XFile? galleryResult;

  @override
  Future<XFile?> pickFromCamera() async => null;

  @override
  Future<XFile?> pickFromGallery() async => galleryResult;
}

class FakeLocalImageStore implements LocalImageStore {
  @override
  Future<String> save(
    XFile source, {
    required String category,
    String? previousPath,
  }) async => '/fake/$category/photo.jpg';

  @override
  Future<void> delete(String path) async {}
}

ProviderContainer buildBikeTestContainer({
  ImagePickerService? imagePickerService,
}) {
  final container = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWith(
        (ref) => AppDatabase(NativeDatabase.memory()),
      ),
      imagePickerServiceProvider.overrideWith(
        (ref) => imagePickerService ?? FakeImagePickerService(),
      ),
      localImageStoreProvider.overrideWith((ref) => FakeLocalImageStore()),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

/// Mirrors the app's single `/profile/bikes/:bikeId` route (there's no
/// separate literal route for "new" — see [newBikeRouteId]) plus a stub for
/// `/profile/bikes` itself, since Save (new bike) and Delete both navigate.
Future<void> pumpBikeDetail(
  WidgetTester tester,
  ProviderContainer container, {
  required String bikeId,
}) async {
  final router = GoRouter(
    initialLocation: '/profile/bikes/$bikeId',
    routes: [
      GoRoute(
        path: '/profile/bikes',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: Scaffold(body: Text('Bikes list')),
        ),
      ),
      GoRoute(
        path: '/profile/bikes/:bikeId',
        pageBuilder: (context, state) => NoTransitionPage(
          child: BikeDetailScreen(bikeId: state.pathParameters['bikeId']!),
        ),
      ),
    ],
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

Bike makeTestBike(String id, String nickname) {
  final now = DateTime.now();
  return Bike(id: id, nickname: nickname, createdAt: now, updatedAt: now);
}
