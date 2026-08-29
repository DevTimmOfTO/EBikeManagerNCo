import 'dart:convert';

import 'package:ebikemanager/features/repair/domain/entities/repair_guide.dart';
import 'package:ebikemanager/features/repair/domain/repositories/repair_guide_repository.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'asset_repair_guide_repository.g.dart';

class AssetRepairGuideRepository implements RepairGuideRepository {
  const AssetRepairGuideRepository({
    this.assetPath = 'assets/repair_guides/guides.json',
  });

  final String assetPath;

  @override
  Future<List<RepairGuide>> loadAllGuides() async {
    final raw = await rootBundle.loadString(assetPath);
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .cast<Map<String, dynamic>>()
        .map(RepairGuide.fromJson)
        .toList(growable: false);
  }

  @override
  Future<RepairGuide?> findBySlug(String slug) async {
    final guides = await loadAllGuides();
    for (final guide in guides) {
      if (guide.slug == slug) return guide;
    }
    return null;
  }
}

@riverpod
RepairGuideRepository repairGuideRepository(Ref ref) =>
    const AssetRepairGuideRepository();
