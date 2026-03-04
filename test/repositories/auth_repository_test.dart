import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:wandb_viewer/repositories/auth_repository.dart';

@GenerateMocks([GraphQLClient])
import 'auth_repository_test.mocks.dart';

void main() {
  late MockGraphQLClient mockClient;
  late AuthRepository repo;

  setUp(() {
    mockClient = MockGraphQLClient();
    repo = AuthRepository(mockClient);
  });

  test('validateApiKey returns User on success', () async {
    when(mockClient.query(any)).thenAnswer((_) async => QueryResult(
      data: {
        'viewer': {
          'id': '1',
          'username': 'testuser',
          'email': 'test@test.com',
          'teams': {'edges': [{'node': {'name': 'my-team'}}]},
        }
      },
      options: QueryOptions(document: gql('')),
      source: QueryResultSource.network,
    ));

    final user = await repo.validateApiKey();
    expect(user.username, 'testuser');
    expect(user.teams, ['my-team']);
  });

  test('validateApiKey throws on error', () async {
    when(mockClient.query(any)).thenAnswer((_) async => QueryResult(
      exception: OperationException(
        graphqlErrors: [const GraphQLError(message: 'Unauthorized')],
      ),
      options: QueryOptions(document: gql('')),
      source: QueryResultSource.network,
    ));

    expect(() => repo.validateApiKey(), throwsException);
  });
}
