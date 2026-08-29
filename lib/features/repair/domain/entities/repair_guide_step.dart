import 'package:freezed_annotation/freezed_annotation.dart';

part 'repair_guide_step.freezed.dart';
part 'repair_guide_step.g.dart';

@freezed
abstract class RepairGuideStep with _$RepairGuideStep {
  const factory RepairGuideStep({
    required int stepNumber,
    required String instruction,
    String? imagePath,
  }) = _RepairGuideStep;

  factory RepairGuideStep.fromJson(Map<String, Object?> json) =>
      _$RepairGuideStepFromJson(json);
}
