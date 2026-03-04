import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import '../core/constants.dart';
import '../graphql/queries/runs.dart';
import '../models/run.dart';
import 'notification_service.dart';

const _taskName = 'checkRunStatus';
const _statesKey = 'bg_run_states';
const _bgEntityKey = 'bg_entity';
const _bgProjectKey = 'bg_project';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task != _taskName) return true;

    try {
      await NotificationService.initialize();

      const storage = FlutterSecureStorage();
      final apiKey = await storage.read(key: AppConstants.apiKeyStorageKey);
      if (apiKey == null) return true;

      final prefs = await SharedPreferences.getInstance();
      final entity = prefs.getString(_bgEntityKey);
      final project = prefs.getString(_bgProjectKey);
      if (entity == null || project == null) return true;

      // Query active runs
      final httpLink = HttpLink(AppConstants.wandbGraphqlUrl);
      final authLink = AuthLink(getToken: () => 'Bearer $apiKey');
      final client = GraphQLClient(
        link: authLink.concat(httpLink),
        cache: GraphQLCache(),
      );

      final result = await client.query(QueryOptions(
        document: gql(runsQuery),
        variables: {
          'entity': entity,
          'project': project,
          'first': 50,
          'order': '-createdAt',
        },
        fetchPolicy: FetchPolicy.networkOnly,
      ));

      if (result.hasException) return true;

      final projectData = result.data!['project'] as Map<String, dynamic>;
      final runsData = projectData['runs'] as Map<String, dynamic>;
      final edges = runsData['edges'] as List;
      final runs = edges
          .map((e) => Run.fromGraphQL(e['node'] as Map<String, dynamic>))
          .toList();

      // Load previous states
      final prevStatesJson = prefs.getString(_statesKey);
      final prevStates = prevStatesJson != null
          ? Map<String, String>.from(json.decode(prevStatesJson) as Map)
          : <String, String>{};

      // Check for state changes
      final newStates = <String, String>{};
      for (final run in runs) {
        final stateStr = run.state.name;
        newStates[run.name] = stateStr;

        final prevState = prevStates[run.name];
        if (prevState != null && prevState != stateStr) {
          // State changed
          if (stateStr == 'finished' ||
              stateStr == 'crashed' ||
              stateStr == 'failed') {
            await NotificationService.showRunStateChanged(
              runName: run.displayName ?? run.name,
              newState: stateStr,
              projectName: project,
            );
          }
        }
      }

      // Save new states
      await prefs.setString(_statesKey, json.encode(newStates));
    } catch (_) {
      // Silently fail in background
    }

    return true;
  });
}

class BackgroundService {
  static Future<void> initialize() async {
    await Workmanager().initialize(callbackDispatcher);
  }

  static Future<void> registerPeriodicTask() async {
    await Workmanager().registerPeriodicTask(
      'wandb-run-check',
      _taskName,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }

  static Future<void> cancelAll() async {
    await Workmanager().cancelAll();
  }

  /// Store current entity/project for background checks
  static Future<void> setActiveProject(
      String entity, String project) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_bgEntityKey, entity);
    await prefs.setString(_bgProjectKey, project);
  }
}
