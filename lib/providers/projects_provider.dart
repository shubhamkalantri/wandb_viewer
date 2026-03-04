import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/project.dart';
import '../providers/auth_provider.dart';
import '../repositories/project_repository.dart';

final projectsProvider = AsyncNotifierProvider.family<ProjectsNotifier,
    List<Project>, String>(ProjectsNotifier.new);

class ProjectsNotifier extends FamilyAsyncNotifier<List<Project>, String> {
  String? _endCursor;
  bool _hasMore = true;

  @override
  Future<List<Project>> build(String entity) async {
    return _fetchProjects(entity);
  }

  Future<List<Project>> _fetchProjects(String entity) async {
    final client = await ref.read(authenticatedClientProvider.future);
    if (client == null) throw Exception('Not authenticated');

    final repo = ProjectRepository(client);
    final result = await repo.getProjects(entity);
    _endCursor = result.endCursor;
    _hasMore = result.hasNextPage;
    return result.items;
  }

  Future<void> loadMore() async {
    if (!_hasMore || _endCursor == null) return;
    final client = await ref.read(authenticatedClientProvider.future);
    if (client == null) return;

    final current = state.valueOrNull ?? [];
    final repo = ProjectRepository(client);
    final result = await repo.getProjects(arg, cursor: _endCursor);
    _endCursor = result.endCursor;
    _hasMore = result.hasNextPage;
    state = AsyncData([...current, ...result.items]);
  }

  Future<void> refresh() async {
    _endCursor = null;
    _hasMore = true;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchProjects(arg));
  }
}
