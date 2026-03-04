import 'package:graphql_flutter/graphql_flutter.dart';
import '../core/constants.dart';
import '../core/graphql_exception.dart';
import '../graphql/queries/sweeps.dart';
import '../models/sweep.dart';
import 'project_repository.dart';

class SweepRepository {
  final GraphQLClient _client;

  SweepRepository(this._client);

  Future<PagedResult<Sweep>> getSweeps(
    String entity,
    String project, {
    String? cursor,
    int first = AppConstants.defaultPageSize,
  }) async {
    final result = await _client.query(QueryOptions(
      document: gql(sweepsQuery),
      variables: {
        'entity': entity,
        'project': project,
        'first': first,
        if (cursor != null) 'cursor': cursor,
      },
      fetchPolicy: FetchPolicy.noCache,
    ));

    throwIfException(result);

    final projectData = result.data!['project'] as Map<String, dynamic>;
    final sweeps = projectData['sweeps'] as Map<String, dynamic>;
    final edges = sweeps['edges'] as List;
    final pageInfo = sweeps['pageInfo'] as Map<String, dynamic>;

    return PagedResult(
      items: edges
          .map((e) =>
              Sweep.fromGraphQL(e['node'] as Map<String, dynamic>))
          .toList(),
      hasNextPage: pageInfo['hasNextPage'] as bool,
      endCursor: pageInfo['endCursor'] as String?,
    );
  }
}
