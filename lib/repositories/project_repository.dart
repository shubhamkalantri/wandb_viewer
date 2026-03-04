import 'package:graphql_flutter/graphql_flutter.dart';
import '../core/constants.dart';
import '../core/graphql_exception.dart';
import '../graphql/queries/projects.dart';
import '../models/project.dart';

class PagedResult<T> {
  final List<T> items;
  final bool hasNextPage;
  final String? endCursor;

  const PagedResult({
    required this.items,
    required this.hasNextPage,
    this.endCursor,
  });
}

class ProjectRepository {
  final GraphQLClient _client;

  ProjectRepository(this._client);

  Future<PagedResult<Project>> getProjects(
    String entity, {
    String? cursor,
    int first = AppConstants.defaultPageSize,
  }) async {
    final result = await _client.query(QueryOptions(
      document: gql(projectsQuery),
      variables: {
        'entity': entity,
        'first': first,
        if (cursor != null) 'cursor': cursor,
      },
      fetchPolicy: FetchPolicy.noCache,
    ));

    throwIfException(result);

    final models = result.data!['models'] as Map<String, dynamic>;
    final edges = models['edges'] as List;
    final pageInfo = models['pageInfo'] as Map<String, dynamic>;

    return PagedResult(
      items: edges
          .map((e) => Project.fromGraphQL(
              e['node'] as Map<String, dynamic>, entity))
          .toList(),
      hasNextPage: pageInfo['hasNextPage'] as bool,
      endCursor: pageInfo['endCursor'] as String?,
    );
  }
}
