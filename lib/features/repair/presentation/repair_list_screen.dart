import 'package:ebikemanager/features/repair/domain/entities/repair_guide.dart';
import 'package:ebikemanager/features/repair/domain/repair_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class RepairListScreen extends ConsumerWidget {
  const RepairListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guidesAsync = ref.watch(filteredRepairGuidesProvider);
    final categoriesAsync = ref.watch(repairGuideCategoriesProvider);
    final selectedCategory = ref.watch(repairGuideCategoryFilterProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Repair')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search guides',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (value) =>
                  ref.read(repairGuideSearchQueryProvider.notifier).query =
                      value,
            ),
          ),
          categoriesAsync.when(
            data: (categories) => _CategoryChips(
              categories: categories,
              selected: selectedCategory,
              onSelected: (category) =>
                  ref
                          .read(repairGuideCategoryFilterProvider.notifier)
                          .category =
                      category,
            ),
            loading: () => const SizedBox.shrink(),
            error: (error, stackTrace) => const SizedBox.shrink(),
          ),
          Expanded(
            child: guidesAsync.when(
              data: (guides) {
                if (guides.isEmpty) {
                  return const Center(
                    child: Text('No guides match your search.'),
                  );
                }
                return ListView.builder(
                  itemCount: guides.length,
                  itemBuilder: (context, index) =>
                      _GuideListTile(guide: guides[index]),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) =>
                  Center(child: Text('Failed to load guides: $error')),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  final List<String> categories;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: const Text('All'),
              selected: selected == null,
              onSelected: (_) => onSelected(null),
            ),
          ),
          for (final category in categories)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                label: Text(category),
                selected: selected == category,
                onSelected: (_) =>
                    onSelected(selected == category ? null : category),
              ),
            ),
        ],
      ),
    );
  }
}

class _GuideListTile extends StatelessWidget {
  const _GuideListTile({required this.guide});

  final RepairGuide guide;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(guide.title),
      subtitle: Text(guide.summary),
      leading: _DifficultyBadge(difficulty: guide.difficulty),
      trailing: Text('${guide.estimatedTimeMinutes} min'),
      onTap: () => context.go('/repair/${guide.slug}'),
    );
  }
}

class _DifficultyBadge extends StatelessWidget {
  const _DifficultyBadge({required this.difficulty});

  final RepairDifficulty difficulty;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (difficulty) {
      RepairDifficulty.beginner => (Colors.green, 'B'),
      RepairDifficulty.intermediate => (Colors.orange, 'I'),
      RepairDifficulty.advanced => (Colors.red, 'A'),
    };

    return Tooltip(
      message: difficulty.name,
      child: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.2),
        foregroundColor: color,
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
