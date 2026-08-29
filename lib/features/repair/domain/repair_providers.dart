import 'package:ebikemanager/features/repair/data/asset_repair_guide_repository.dart';
import 'package:ebikemanager/features/repair/domain/entities/repair_guide.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'repair_providers.g.dart';

@riverpod
Future<List<RepairGuide>> allRepairGuides(Ref ref) =>
    ref.watch(repairGuideRepositoryProvider).loadAllGuides();

@riverpod
Future<RepairGuide?> repairGuideBySlug(Ref ref, String slug) =>
    ref.watch(repairGuideRepositoryProvider).findBySlug(slug);

@riverpod
class RepairGuideSearchQuery extends _$RepairGuideSearchQuery {
  @override
  String build() => '';

  String get query => state;

  set query(String value) => state = value;
}

/// `null` means "all categories".
@riverpod
class RepairGuideCategoryFilter extends _$RepairGuideCategoryFilter {
  @override
  String? build() => null;

  String? get category => state;

  set category(String? value) => state = value;
}

@riverpod
Future<List<String>> repairGuideCategories(Ref ref) async {
  final guides = await ref.watch(allRepairGuidesProvider.future);
  final categories = guides.map((guide) => guide.category).toSet().toList()
    ..sort();
  return categories;
}

@riverpod
Future<List<RepairGuide>> filteredRepairGuides(Ref ref) async {
  final guides = await ref.watch(allRepairGuidesProvider.future);
  final query = ref.watch(repairGuideSearchQueryProvider).trim().toLowerCase();
  final category = ref.watch(repairGuideCategoryFilterProvider);

  return guides.where((guide) {
    if (category != null && guide.category != category) return false;
    if (query.isEmpty) return true;
    return guide.title.toLowerCase().contains(query) ||
        guide.summary.toLowerCase().contains(query);
  }).toList();
}
