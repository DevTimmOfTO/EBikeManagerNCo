import 'package:ebikemanager/features/repair/domain/entities/repair_guide_step.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'repair_guide.freezed.dart';
part 'repair_guide.g.dart';

enum RepairDifficulty { beginner, intermediate, advanced }

@freezed
abstract class RepairGuide with _$RepairGuide {
  const factory RepairGuide({
    required String slug,
    required String title,
    required String category,
    required RepairDifficulty difficulty,
    required int estimatedTimeMinutes,
    required String summary,
    required List<String> toolsRequired,
    required List<RepairGuideStep> steps,

    /// Where this guide's content came from, e.g. `"bundled"`.
    required String source,

    /// Outbound link (e.g. iFixit) offered instead of embedding third-party
    /// content, to avoid CC BY-NC-SA/F-Droid distribution conflicts.
    String? outboundUrl,
  }) = _RepairGuide;

  factory RepairGuide.fromJson(Map<String, Object?> json) =>
      _$RepairGuideFromJson(json);
}
