import 'package:ebikemanager/features/repair/domain/entities/repair_guide.dart';

abstract class RepairGuideRepository {
  Future<List<RepairGuide>> loadAllGuides();

  Future<RepairGuide?> findBySlug(String slug);
}
