import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/run.dart';
import '../../providers/runs_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/background_service.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_view.dart';
import '../../widgets/poll_status_indicator.dart';
import 'run_card.dart';
import 'run_filter_bar.dart';

class RunsScreen extends ConsumerStatefulWidget {
  final String entity;
  final String project;

  const RunsScreen({super.key, required this.entity, required this.project});

  @override
  ConsumerState<RunsScreen> createState() => _RunsScreenState();
}

class _RunsScreenState extends ConsumerState<RunsScreen> {
  RunFilter _filter = RunFilter.active;
  final Set<String> _selectedRunNames = {};

  @override
  void initState() {
    super.initState();
    BackgroundService.setActiveProject(widget.entity, widget.project);
  }

  RunsParams get _params =>
      RunsParams(entity: widget.entity, project: widget.project, filter: _filter);

  void _toggleSelection(Run run) {
    setState(() {
      if (_selectedRunNames.contains(run.name)) {
        _selectedRunNames.remove(run.name);
      } else {
        _selectedRunNames.add(run.name);
      }
    });
  }

  void _navigateToCompare() {
    final names = _selectedRunNames.map(Uri.encodeComponent).join(',');
    context.push(
      '/projects/${Uri.encodeComponent(widget.entity)}/${Uri.encodeComponent(widget.project)}/compare?runs=$names',
    );
  }

  @override
  Widget build(BuildContext context) {
    final runsAsync = ref.watch(runsProvider(_params));
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.project),
        actions: [
          PollStatusIndicator(
            isPolling: true,
            interval: settings.pollInterval,
          ),
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Sweeps',
            onPressed: () => context.push(
              '/projects/${Uri.encodeComponent(widget.entity)}/${Uri.encodeComponent(widget.project)}/sweeps',
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          RunFilterBar(
            current: _filter,
            onChanged: (f) => setState(() => _filter = f),
          ),
          Expanded(
            child: runsAsync.when(
              loading: () =>
                  const LoadingIndicator(message: 'Loading runs...'),
              error: (e, _) => ErrorView(
                message: 'Failed to load runs. Check your connection and try again.',
                onRetry: () => ref.invalidate(runsProvider(_params)),
              ),
              data: (runs) {
                if (runs.isEmpty) {
                  return const Center(child: Text('No runs found'));
                }

                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(runsProvider(_params).notifier).refresh(),
                  child: ListView.builder(
                    itemCount: runs.length,
                    itemBuilder: (context, index) {
                      final run = runs[index];
                      return RunCard(
                        run: run,
                        selected: _selectedRunNames.contains(run.name),
                        onTap: () {
                          if (_selectedRunNames.isNotEmpty) {
                            _toggleSelection(run);
                          } else {
                            context.push(
                              '/projects/${Uri.encodeComponent(widget.entity)}/${Uri.encodeComponent(widget.project)}/runs/${Uri.encodeComponent(run.name)}',
                            );
                          }
                        },
                        onLongPress: () => _toggleSelection(run),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _selectedRunNames.length >= 2
          ? FloatingActionButton.extended(
              onPressed: _navigateToCompare,
              icon: const Icon(Icons.compare_arrows),
              label: Text('Compare (${_selectedRunNames.length})'),
            )
          : null,
    );
  }
}
