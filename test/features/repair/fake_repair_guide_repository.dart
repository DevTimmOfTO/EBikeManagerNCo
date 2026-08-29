import 'package:ebikemanager/features/repair/domain/entities/repair_guide.dart';
import 'package:ebikemanager/features/repair/domain/entities/repair_guide_step.dart';
import 'package:ebikemanager/features/repair/domain/repositories/repair_guide_repository.dart';

/// A small in-memory stand-in used by widget tests so they don't depend on
/// real asset I/O (which needs a real event-loop turn that `pumpAndSettle`'s
/// fake-time simulation never provides) — see
/// `asset_repair_guide_repository_test.dart` for the dedicated,
/// real-asset-loading test of the production repository.
class FakeRepairGuideRepository implements RepairGuideRepository {
  static final guides = [
    RepairGuide(
      slug: 'flat-tire-repair',
      title: 'Flat Tire Repair',
      category: 'Tires',
      difficulty: RepairDifficulty.beginner,
      estimatedTimeMinutes: 30,
      summary: 'Fix a puncture and get rolling again.',
      toolsRequired: const ['Tire levers', 'Pump'],
      source: 'bundled',
      steps: List.generate(
        7,
        (i) => RepairGuideStep(
          stepNumber: i + 1,
          instruction: i == 0
              ? 'Shift to the smallest rear cog to slacken the chain, '
                    'then remove the wheel.'
              : 'Step ${i + 1} instruction.',
        ),
      ),
    ),
    const RepairGuide(
      slug: 'tire-pressure-check',
      title: 'Tire Pressure Check',
      category: 'Tires',
      difficulty: RepairDifficulty.beginner,
      estimatedTimeMinutes: 5,
      summary: 'A quick habit that improves ride comfort.',
      toolsRequired: ['Pressure gauge'],
      source: 'bundled',
      steps: [
        RepairGuideStep(
          stepNumber: 1,
          instruction: 'Check the sidewall for the recommended range.',
        ),
      ],
    ),
    const RepairGuide(
      slug: 'basic-battery-care',
      title: 'Basic Battery Care',
      category: 'Battery',
      difficulty: RepairDifficulty.beginner,
      estimatedTimeMinutes: 10,
      summary: 'Simple habits that keep your battery healthy.',
      toolsRequired: ['Soft cloth'],
      source: 'bundled',
      steps: [
        RepairGuideStep(
          stepNumber: 1,
          instruction: 'Keep charge between 20% and 80%.',
        ),
      ],
    ),
  ];

  @override
  Future<List<RepairGuide>> loadAllGuides() async => guides;

  @override
  Future<RepairGuide?> findBySlug(String slug) async {
    for (final guide in guides) {
      if (guide.slug == slug) return guide;
    }
    return null;
  }
}
