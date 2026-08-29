import 'package:drift/native.dart';
import 'package:ebikemanager/core/database/app_database.dart';
import 'package:ebikemanager/main.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App boots to the Dashboard tab', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWith(
            (ref) => AppDatabase(NativeDatabase.memory()),
          ),
        ],
        child: const EBikeManagerApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsWidgets);

    // Drift schedules a zero-duration debounce Timer when a watched query is
    // torn down; unmount here (inside the test body, where we can still
    // pump) so it fires before flutter_test's end-of-test "no pending
    // timers" check runs during the framework's own teardown.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(Duration.zero);
  });
}
