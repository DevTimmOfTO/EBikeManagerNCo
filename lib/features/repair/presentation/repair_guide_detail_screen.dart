import 'package:ebikemanager/features/repair/domain/entities/repair_guide.dart';
import 'package:ebikemanager/features/repair/domain/entities/repair_guide_step.dart';
import 'package:ebikemanager/features/repair/domain/repair_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class RepairGuideDetailScreen extends ConsumerWidget {
  const RepairGuideDetailScreen({required this.slug, super.key});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guideAsync = ref.watch(repairGuideBySlugProvider(slug));

    return Scaffold(
      appBar: AppBar(title: const Text('Guide')),
      body: guideAsync.when(
        data: (guide) {
          if (guide == null) {
            return const Center(child: Text('Guide not found.'));
          }
          return _GuideDetail(guide: guide);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            Center(child: Text('Failed to load guide: $error')),
      ),
    );
  }
}

class _GuideDetail extends StatefulWidget {
  const _GuideDetail({required this.guide});

  final RepairGuide guide;

  @override
  State<_GuideDetail> createState() => _GuideDetailState();
}

class _GuideDetailState extends State<_GuideDetail> {
  final _pageController = PageController();
  int _stepIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final guide = widget.guide;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(guide.title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text(guide.summary, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            Chip(label: Text(guide.category)),
            Chip(label: Text(guide.difficulty.name)),
            Chip(label: Text('${guide.estimatedTimeMinutes} min')),
          ],
        ),
        if (guide.outboundUrl != null) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _openOutboundLink(context, guide.outboundUrl!),
            icon: const Icon(Icons.open_in_new),
            label: const Text('View on iFixit'),
          ),
        ],
        const SizedBox(height: 16),
        Text('Tools required', style: Theme.of(context).textTheme.titleMedium),
        for (final tool in guide.toolsRequired)
          CheckboxListTile(
            title: Text(tool),
            value: false,
            onChanged: (_) {},
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
        const SizedBox(height: 16),
        Text('Steps', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        SizedBox(
          height: 260,
          child: PageView.builder(
            controller: _pageController,
            itemCount: guide.steps.length,
            onPageChanged: (index) => setState(() => _stepIndex = index),
            itemBuilder: (context, index) => _StepCard(
              step: guide.steps[index],
              totalSteps: guide.steps.length,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: _stepIndex == 0 ? null : _goToPreviousStep,
              icon: const Icon(Icons.chevron_left),
              label: const Text('Previous'),
            ),
            Text('${_stepIndex + 1} / ${guide.steps.length}'),
            TextButton.icon(
              onPressed: _stepIndex == guide.steps.length - 1
                  ? null
                  : _goToNextStep,
              icon: const Icon(Icons.chevron_right),
              label: const Text('Next'),
            ),
          ],
        ),
      ],
    );
  }

  void _goToPreviousStep() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 200),
      curve: Curves.ease,
    );
  }

  void _goToNextStep() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 200),
      curve: Curves.ease,
    );
  }

  Future<void> _openOutboundLink(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not open $url')));
    }
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.step, required this.totalSteps});

  final RepairGuideStep step;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Step ${step.stepNumber} of $totalSteps',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            if (step.imagePath != null)
              Expanded(child: Image.asset(step.imagePath!, fit: BoxFit.contain))
            else
              Expanded(
                child: Center(
                  child: Icon(
                    Icons.build_outlined,
                    size: 48,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Text(step.instruction),
          ],
        ),
      ),
    );
  }
}
