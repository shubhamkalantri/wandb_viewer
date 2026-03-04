import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/login/login_screen.dart';
import '../screens/projects/projects_screen.dart';
import '../screens/runs/runs_screen.dart';
import '../screens/run_detail/run_detail_screen.dart';
import '../screens/compare/compare_runs_screen.dart';
import '../screens/sweeps/sweeps_screen.dart';
import '../screens/sweeps/sweep_detail_screen.dart';
import '../screens/settings/settings_screen.dart';

/// A [ChangeNotifier] that fires when the auth state changes,
/// used by GoRouter's refreshListenable to re-evaluate redirects
/// without recreating the entire router.
class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier(Ref ref) {
    ref.listen(authStateProvider, (_, __) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = _AuthNotifier(ref);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final isLoggedIn = authState.valueOrNull != null;
      final isLoginRoute = state.matchedLocation == '/login';

      if (!isLoggedIn && !isLoginRoute) return '/login';
      if (isLoggedIn && isLoginRoute) return '/projects';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      ),
      GoRoute(
        path: '/projects',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ProjectsScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      ),
      GoRoute(
        path: '/projects/:entity/:project/runs',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: RunsScreen(
            entity: state.pathParameters['entity'] ?? '',
            project: state.pathParameters['project'] ?? '',
          ),
        ),
      ),
      GoRoute(
        path: '/projects/:entity/:project/runs/:runName',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: RunDetailScreen(
            entity: state.pathParameters['entity'] ?? '',
            project: state.pathParameters['project'] ?? '',
            runName: state.pathParameters['runName'] ?? '',
          ),
        ),
      ),
      GoRoute(
        path: '/projects/:entity/:project/compare',
        pageBuilder: (context, state) {
          final runNames = (state.uri.queryParameters['runs'] ?? '')
              .split(',')
              .where((s) => s.isNotEmpty)
              .map(Uri.decodeComponent)
              .toList();
          return MaterialPage(
            key: state.pageKey,
            child: CompareRunsScreen(
              entity: state.pathParameters['entity'] ?? '',
              project: state.pathParameters['project'] ?? '',
              runNames: runNames,
            ),
          );
        },
      ),
      GoRoute(
        path: '/projects/:entity/:project/sweeps',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: SweepsScreen(
            entity: state.pathParameters['entity'] ?? '',
            project: state.pathParameters['project'] ?? '',
          ),
        ),
      ),
      GoRoute(
        path: '/projects/:entity/:project/sweeps/:sweepId',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: SweepDetailScreen(
            entity: state.pathParameters['entity'] ?? '',
            project: state.pathParameters['project'] ?? '',
            sweepId: state.pathParameters['sweepId'] ?? '',
          ),
        ),
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const SettingsScreen(),
        ),
      ),
    ],
  );
});
