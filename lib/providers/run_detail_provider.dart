import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/run.dart';
import '../models/metric_history.dart';
import '../models/system_metrics.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../repositories/run_repository.dart';

class RunDetailParams {
  final String entity;
  final String project;
  final String runName;

  const RunDetailParams({
    required this.entity,
    required this.project,
    required this.runName,
  });

  @override
  bool operator ==(Object other) =>
      other is RunDetailParams &&
      other.entity == entity &&
      other.project == project &&
      other.runName == runName;

  @override
  int get hashCode => Object.hash(entity, project, runName);
}

final runDetailProvider = AsyncNotifierProvider.family<RunDetailNotifier, Run,
    RunDetailParams>(RunDetailNotifier.new);

class RunDetailNotifier extends FamilyAsyncNotifier<Run, RunDetailParams> {
  Timer? _pollTimer;

  @override
  Future<Run> build(RunDetailParams params) async {
    ref.onDispose(() => _pollTimer?.cancel());
    final run = await _fetch();
    if (run.isActive) _startPolling();
    return run;
  }

  Future<Run> _fetch() async {
    final client = await ref.read(authenticatedClientProvider.future);
    if (client == null) throw Exception('Not authenticated');
    return RunRepository(client)
        .getRunDetail(arg.entity, arg.project, arg.runName);
  }

  void _startPolling() {
    final interval = ref.read(settingsProvider).pollInterval;
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(interval, (_) async {
      try {
        final run = await _fetch();
        state = AsyncData(run);
        if (!run.isActive) _pollTimer?.cancel();
      } catch (_) {}
    });
  }
}

final runMetricsProvider = FutureProvider.family<List<MetricHistory>,
    ({RunDetailParams params, List<String> keys})>((ref, args) async {
  final client = await ref.read(authenticatedClientProvider.future);
  if (client == null) throw Exception('Not authenticated');
  return RunRepository(client).getMetricHistory(
    args.params.entity,
    args.params.project,
    args.params.runName,
    args.keys,
  );
});

final runSystemMetricsProvider =
    FutureProvider.family<SystemMetrics, RunDetailParams>((ref, params) async {
  final client = await ref.read(authenticatedClientProvider.future);
  if (client == null) throw Exception('Not authenticated');
  return RunRepository(client).getSystemMetrics(
    params.entity,
    params.project,
    params.runName,
  );
});

final runFilesProvider = FutureProvider.family<List<RunFile>, RunDetailParams>(
    (ref, params) async {
  final client = await ref.read(authenticatedClientProvider.future);
  if (client == null) throw Exception('Not authenticated');
  return RunRepository(client).getRunFiles(
    params.entity,
    params.project,
    params.runName,
  );
});
