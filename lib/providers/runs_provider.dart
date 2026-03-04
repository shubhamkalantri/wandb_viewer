import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/run.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../repositories/run_repository.dart';
import '../screens/runs/run_filter_bar.dart';

class RunsParams {
  final String entity;
  final String project;
  final RunFilter filter;

  const RunsParams({
    required this.entity,
    required this.project,
    this.filter = RunFilter.active,
  });

  @override
  bool operator ==(Object other) =>
      other is RunsParams &&
      other.entity == entity &&
      other.project == project &&
      other.filter == filter;

  @override
  int get hashCode => Object.hash(entity, project, filter);
}

final runsProvider = AsyncNotifierProvider.family<RunsNotifier,
    List<Run>, RunsParams>(RunsNotifier.new);

class RunsNotifier extends FamilyAsyncNotifier<List<Run>, RunsParams> {
  Timer? _pollTimer;
  bool _refreshing = false;

  @override
  Future<List<Run>> build(RunsParams params) async {
    ref.onDispose(() => _pollTimer?.cancel());
    _startPolling();
    return _fetchRuns();
  }

  Future<List<Run>> _fetchRuns() async {
    final client = await ref.read(authenticatedClientProvider.future);
    if (client == null) throw Exception('Not authenticated');

    final repo = RunRepository(client);
    final filters = arg.filter == RunFilter.active
        ? {'state': 'running'}
        : null;
    final result = await repo.getRuns(
      arg.entity,
      arg.project,
      filters: filters,
      order: '-createdAt',
    );
    return result.items;
  }

  void _startPolling() {
    final interval = ref.read(settingsProvider).pollInterval;
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(interval, (_) => refresh());
  }

  Future<void> refresh() async {
    if (_refreshing) return;
    _refreshing = true;
    try {
      final runs = await _fetchRuns();
      state = AsyncData(runs);
    } catch (e, st) {
      state = AsyncError(e, st);
    } finally {
      _refreshing = false;
    }
  }
}
