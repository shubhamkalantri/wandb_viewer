import 'dart:convert';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../core/constants.dart';
import '../core/graphql_exception.dart';
import '../graphql/queries/runs.dart';
import '../graphql/queries/run_detail.dart';
import '../graphql/queries/run_history.dart';
import '../graphql/queries/run_files.dart';
import '../models/run.dart';
import '../models/metric_history.dart';
import '../models/system_metrics.dart';
import 'project_repository.dart';

class RunFile {
  final String name;
  final String url;
  final int? sizeBytes;

  const RunFile({required this.name, required this.url, this.sizeBytes});
}

class RunRepository {
  final GraphQLClient _client;

  RunRepository(this._client);

  Future<PagedResult<Run>> getRuns(
    String entity,
    String project, {
    String? cursor,
    Map<String, dynamic>? filters,
    String? order,
    int first = AppConstants.defaultPageSize,
  }) async {
    final result = await _client.query(QueryOptions(
      document: gql(runsQuery),
      variables: {
        'entity': entity,
        'project': project,
        'first': first,
        if (cursor != null) 'cursor': cursor,
        if (filters != null) 'filters': json.encode(filters),
        if (order != null) 'order': order,
      },
      fetchPolicy: FetchPolicy.noCache,
    ));

    throwIfException(result);

    final projectData = result.data!['project'] as Map<String, dynamic>;
    final runs = projectData['runs'] as Map<String, dynamic>;
    final edges = runs['edges'] as List;
    final pageInfo = runs['pageInfo'] as Map<String, dynamic>;

    return PagedResult(
      items: edges
          .map((e) => Run.fromGraphQL(e['node'] as Map<String, dynamic>))
          .toList(),
      hasNextPage: pageInfo['hasNextPage'] as bool,
      endCursor: pageInfo['endCursor'] as String?,
    );
  }

  Future<Run> getRunDetail(
      String entity, String project, String runName) async {
    final result = await _client.query(QueryOptions(
      document: gql(runDetailQuery),
      variables: {
        'entity': entity,
        'project': project,
        'runName': runName,
      },
      fetchPolicy: FetchPolicy.noCache,
    ));

    throwIfException(result);

    final projectData = result.data!['project'] as Map<String, dynamic>;
    return Run.fromGraphQL(projectData['run'] as Map<String, dynamic>);
  }

  Future<List<MetricHistory>> getMetricHistory(
    String entity,
    String project,
    String runName,
    List<String> metricKeys, {
    int samples = AppConstants.defaultHistorySamples,
  }) async {
    // W&B API expects specs as JSON-encoded strings (JSONString type)
    final specs = metricKeys
        .map((k) => json.encode({'keys': [k], 'samples': samples}))
        .toList();
    final result = await _client.query(QueryOptions(
      document: gql(runHistoryQuery),
      variables: {
        'entity': entity,
        'project': project,
        'runName': runName,
        'specs': specs,
      },
      fetchPolicy: FetchPolicy.noCache,
    ));

    throwIfException(result);

    final projectData = result.data?['project'] as Map<String, dynamic>?;
    final run = projectData?['run'] as Map<String, dynamic>?;
    final sampledHistory = run?['sampledHistory'] as List? ?? [];

    // sampledHistory returns an array of arrays, one per spec
    // Each row may be a Map (pre-parsed JSON) or a String (JSON-encoded)
    return List.generate(metricKeys.length, (i) {
      if (i >= sampledHistory.length) {
        return MetricHistory(key: metricKeys[i], points: []);
      }
      final rawRows = sampledHistory[i] as List? ?? [];
      final rows = rawRows.map((row) {
        if (row is Map<String, dynamic>) return row;
        if (row is String) {
          try {
            return json.decode(row) as Map<String, dynamic>;
          } catch (_) {
            return <String, dynamic>{};
          }
        }
        return <String, dynamic>{};
      }).toList();
      return MetricHistory.fromSampledHistory(metricKeys[i], rows);
    });
  }

  Future<SystemMetrics> getSystemMetrics(
    String entity,
    String project,
    String runName, {
    int samples = AppConstants.defaultHistorySamples,
  }) async {
    final result = await _client.query(QueryOptions(
      document: gql(runEventsQuery),
      variables: {
        'entity': entity,
        'project': project,
        'runName': runName,
        'samples': samples,
      },
      fetchPolicy: FetchPolicy.noCache,
    ));

    throwIfException(result);

    final projectData = result.data?['project'] as Map<String, dynamic>?;
    final run = projectData?['run'] as Map<String, dynamic>?;
    final events = run?['events'] as List? ?? [];
    return SystemMetrics.fromEvents(events);
  }

  Future<List<RunFile>> getRunFiles(
    String entity,
    String project,
    String runName, {
    int first = 100,
  }) async {
    final result = await _client.query(QueryOptions(
      document: gql(runFilesQuery),
      variables: {
        'entity': entity,
        'project': project,
        'runName': runName,
        'first': first,
      },
      fetchPolicy: FetchPolicy.noCache,
    ));

    throwIfException(result);

    final projectData = result.data?['project'] as Map<String, dynamic>?;
    final run = projectData?['run'] as Map<String, dynamic>?;
    final filesMap = run?['files'] as Map<String, dynamic>?;
    final edges = filesMap?['edges'] as List? ?? [];

    return edges.map((e) {
      final node = e['node'] as Map<String, dynamic>;
      final url = (node['directUrl'] ?? node['url'] ?? '') as String;
      return RunFile(
        name: node['name'] as String? ?? '',
        url: url,
        sizeBytes: node['sizeBytes'] as int?,
      );
    }).toList();
  }
}
