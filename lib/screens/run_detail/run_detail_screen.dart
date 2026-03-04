import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/run_detail_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_view.dart';
import '../../widgets/poll_status_indicator.dart';
import '../runs/run_card.dart';
import 'tabs/overview_tab.dart';
import 'tabs/charts_tab.dart';
import 'tabs/system_tab.dart';
import 'tabs/logs_tab.dart';
import 'tabs/media_tab.dart';

class RunDetailScreen extends ConsumerWidget {
  final String entity;
  final String project;
  final String runName;

  const RunDetailScreen({
    super.key,
    required this.entity,
    required this.project,
    required this.runName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = RunDetailParams(
      entity: entity,
      project: project,
      runName: runName,
    );
    final runAsync = ref.watch(runDetailProvider(params));
    final settings = ref.watch(settingsProvider);

    return runAsync.when(
      loading: () => const Scaffold(body: LoadingIndicator(message: 'Loading run...')),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: Text(runName)),
        body: ErrorView(
          message: 'Failed to load run. Check your connection and try again.',
          onRetry: () => ref.invalidate(runDetailProvider(params)),
        ),
      ),
      data: (run) => DefaultTabController(
        length: 5,
        child: Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  run.displayName ?? run.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Row(
                  children: [
                    RunStateBadge(state: run.state),
                    const SizedBox(width: 8),
                    if (run.isActive)
                      PollStatusIndicator(
                        isPolling: true,
                        interval: settings.pollInterval,
                      ),
                  ],
                ),
              ],
            ),
            toolbarHeight: 64,
            bottom: const TabBar(
              isScrollable: true,
              tabs: [
                Tab(text: 'Overview'),
                Tab(text: 'Charts'),
                Tab(text: 'System'),
                Tab(text: 'Logs'),
                Tab(text: 'Media'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              OverviewTab(run: run),
              ChartsTab(run: run, params: params),
              SystemTab(params: params),
              LogsTab(params: params, isActive: run.isActive),
              MediaTab(params: params),
            ],
          ),
        ),
      ),
    );
  }
}
