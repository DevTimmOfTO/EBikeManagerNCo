import 'dart:io';

import 'package:drift/drift.dart';
import 'package:ebikemanager/features/profile/presentation/bike_detail_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

import 'bike_detail_test_helpers.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets('picking a bike photo saves it through the image store', (
    tester,
  ) async {
    final container = buildBikeTestContainer(
      imagePickerService: FakeImagePickerService(
        galleryResult: XFile('${Directory.systemTemp.path}/bike.jpg'),
      ),
    );
    await pumpBikeDetail(tester, container, bikeId: newBikeRouteId);

    await tester.tap(find.text('Add photo').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose from gallery'));
    await tester.pumpAndSettle();

    expect(find.text('Change'), findsWidgets);
  });
}
