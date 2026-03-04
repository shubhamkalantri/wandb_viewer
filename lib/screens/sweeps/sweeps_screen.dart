import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/sweep.dart';
import '../../providers/sweep_provider.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_view.dart';

class SweepsScreen extends ConsumerWidget {
  final String entity;
  final String project;

  const SweepsScreen({
    super.key,
    required this.entity,
    required this.project,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = ProjectParams(entity: entity, project: project);
    final sweepsAsync = ref.watch(sweepsProvider(params));

    return Scaffold(
      appBar: AppBar(title: const Text('Sweeps')),
      body: sweepsAsync.when(
        loading: () => const LoadingIndicator(message: 'Loading sweeps...'),
        error: (e, _) => ErrorView(
          message: 'Failed to load sweeps. Check your connection and try again.',
          onRetry: () => ref.invalidate(sweepsProvider(params)),
        ),
        data: (sweeps) {
          if (sweeps.isEmpty) {
            return const Center(child: Text('No sweeps found'));
          }

          return RefreshIndicator(
            onRefresh: () =>
                ref.read(sweepsProvider(params).notifier).refresh(),
            child: ListView.builder(
              itemCount: sweeps.length,
              itemBuilder: (context, index) => _SweepCard(
                sweep: sweeps[index],
                onTap: () => context.push(
                  '/projects/${Uri.encodeComponent(entity)}/${Uri.encodeComponent(project)}/sweeps/${Uri.encodeComponent(sweeps[index].id)}',
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SweepCard extends StatelessWidget {
  final Sweep sweep;
  final VoidCallback onTap;

  const _SweepCard({required this.sweep, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final stateColor = switch (sweep.state) {
      'RUNNING' => Colors.green,
      'FINISHED' => Colors.blue,
      'PAUSED' => Colors.orange,
      _ => Colors.grey,
    };

    return Card(
      child: ListTile(
        title: Text(sweep.name),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: stateColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                sweep.state ?? 'Unknown',
                style: TextStyle(color: stateColor, fontSize: 12),
              ),
            ),
            const SizedBox(width: 8),
            Text('${sweep.runCount} runs',
                style: theme.textTheme.bodySmall),
          ],
        ),
        trailing: sweep.bestLoss != null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Best Loss', style: theme.textTheme.bodySmall),
                  Text(
                    sweep.bestLoss!.toStringAsFixed(6),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : null,
        onTap: onTap,
      ),
    );
  }
}
