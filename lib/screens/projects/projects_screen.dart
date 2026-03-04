import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/projects_provider.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_view.dart';
import 'project_card.dart';

class ProjectsScreen extends ConsumerWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      loading: () => const Scaffold(body: LoadingIndicator()),
      error: (e, _) => Scaffold(
        body: const ErrorView(message: 'Authentication error. Please try logging in again.'),
      ),
      data: (user) {
        if (user == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go('/login');
          });
          return const SizedBox.shrink();
        }

        final entities = [user.username, ...user.teams];
        return DefaultTabController(
          length: entities.length,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Projects'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () => context.push('/settings'),
                ),
              ],
              bottom: entities.length > 1
                  ? TabBar(
                      isScrollable: true,
                      tabs: entities.map((e) => Tab(text: e)).toList(),
                    )
                  : null,
            ),
            body: TabBarView(
              children: entities
                  .map((entity) => _ProjectsList(entity: entity))
                  .toList(),
            ),
          ),
        );
      },
    );
  }
}

class _ProjectsList extends ConsumerWidget {
  final String entity;
  const _ProjectsList({required this.entity});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(projectsProvider(entity));

    return projectsAsync.when(
      loading: () => const LoadingIndicator(message: 'Loading projects...'),
      error: (e, _) => ErrorView(
        message: 'Failed to load projects. Check your connection and try again.',
        onRetry: () => ref.invalidate(projectsProvider(entity)),
      ),
      data: (projects) => RefreshIndicator(
        onRefresh: () =>
            ref.read(projectsProvider(entity).notifier).refresh(),
        child: projects.isEmpty
            ? const Center(child: Text('No projects found'))
            : ListView.builder(
                itemCount: projects.length,
                itemBuilder: (context, index) => ProjectCard(
                  project: projects[index],
                  onTap: () => context.push(
                    '/projects/${Uri.encodeComponent(projects[index].entityName)}/${Uri.encodeComponent(projects[index].name)}/runs',
                  ),
                ),
              ),
      ),
    );
  }
}
