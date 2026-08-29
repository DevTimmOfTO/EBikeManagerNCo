import 'package:ebikemanager/features/repair/data/asset_repair_guide_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // rootBundle.loadString needs a real (non-fake-async) event loop turn to
  // resolve; TestWidgetsFlutterBinding provides that without requiring a
  // pumped widget tree, so plain `test()` is used here instead of
  // `testWidgets()` + pump/pumpAndSettle.
  TestWidgetsFlutterBinding.ensureInitialized();

  const repository = AssetRepairGuideRepository();

  test('loads all bundled guides with well-formed content', () async {
    final guides = await repository.loadAllGuides();

    expect(guides, isNotEmpty);
    expect(guides.length, greaterThanOrEqualTo(8));

    final slugs = <String>{};
    for (final guide in guides) {
      expect(
        slugs.add(guide.slug),
        isTrue,
        reason: 'duplicate slug: ${guide.slug}',
      );
      expect(guide.title, isNotEmpty);
      expect(guide.category, isNotEmpty);
      expect(guide.summary, isNotEmpty);
      expect(guide.estimatedTimeMinutes, greaterThan(0));
      expect(guide.toolsRequired, isNotEmpty);
      expect(guide.steps, isNotEmpty);
      for (final step in guide.steps) {
        expect(step.instruction, isNotEmpty);
      }
      // Steps should be numbered 1..N in order.
      expect(
        guide.steps.map((s) => s.stepNumber),
        List.generate(guide.steps.length, (i) => i + 1),
      );
    }
  });

  test('findBySlug returns the matching guide, null otherwise', () async {
    final guides = await repository.loadAllGuides();
    final firstSlug = guides.first.slug;

    expect((await repository.findBySlug(firstSlug))?.slug, firstSlug);
    expect(await repository.findBySlug('does-not-exist'), isNull);
  });
}
