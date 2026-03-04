import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/run.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/run_repository.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_view.dart';
import '../runs/run_card.dart';

/// Provider that fetches runs belonging to a sweep
final sweepRunsProvider = FutureProvider.family<List<Run>,
    ({String entity, String project, String sweepId})>((ref, args) async {
  final client = await ref.read(authenticatedClientProvider.future);
  if (client == null) throw Exception('Not authenticated');
  final repo = RunRepository(client);
  // Filter runs by sweep name
  final result = await repo.getRuns(
    args.entity,
    args.project,
    filters: {'sweep': args.sweepId},
    order: '-createdAt',
  );
  return result.items;
});

class SweepDetailScreen extends ConsumerWidget {
  final String entity;
  final String project;
  final String sweepId;

  const SweepDetailScreen({
    super.key,
    required this.entity,
    required this.project,
    required this.sweepId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final runsAsync = ref.watch(sweepRunsProvider((
      entity: entity,
      project: project,
      sweepId: sweepId,
    )));

    return Scaffold(
      appBar: AppBar(title: Text('Sweep: $sweepId')),
      body: runsAsync.when(
        loading: () => const LoadingIndicator(message: 'Loading sweep runs...'),
        error: (e, _) => ErrorView(
          message: 'Failed to load sweep runs. Check your connection and try again.',
          onRetry: () => ref.invalidate(sweepRunsProvider((
            entity: entity,
            project: project,
            sweepId: sweepId,
          ))),
        ),
        data: (runs) {
          if (runs.isEmpty) {
            return const Center(child: Text('No runs in this sweep'));
          }

          return ListView.builder(
            itemCount: runs.length,
            itemBuilder: (context, index) {
              final run = runs[index];
              return RunCard(
                run: run,
                onTap: () => context.push(
                  '/projects/${Uri.encodeComponent(entity)}/${Uri.encodeComponent(project)}/runs/${Uri.encodeComponent(run.name)}',
                ),
              );
            },
          );
        },
      ),
    );
  }
}
