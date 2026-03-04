import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sweep.dart';
import '../providers/auth_provider.dart';
import '../repositories/sweep_repository.dart';

class ProjectParams {
  final String entity;
  final String project;

  const ProjectParams({required this.entity, required this.project});

  @override
  bool operator ==(Object other) =>
      other is ProjectParams &&
      other.entity == entity &&
      other.project == project;

  @override
  int get hashCode => Object.hash(entity, project);
}

final sweepsProvider = AsyncNotifierProvider.family<SweepsNotifier,
    List<Sweep>, ProjectParams>(SweepsNotifier.new);

class SweepsNotifier extends FamilyAsyncNotifier<List<Sweep>, ProjectParams> {
  @override
  Future<List<Sweep>> build(ProjectParams params) async {
    return _fetchSweeps();
  }

  Future<List<Sweep>> _fetchSweeps() async {
    final client = await ref.read(authenticatedClientProvider.future);
    if (client == null) throw Exception('Not authenticated');
    final repo = SweepRepository(client);
    final result = await repo.getSweeps(arg.entity, arg.project);
    return result.items;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchSweeps());
  }
}
