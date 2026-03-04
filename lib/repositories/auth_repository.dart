import 'package:graphql_flutter/graphql_flutter.dart';
import '../graphql/queries/viewer.dart';
import '../models/user.dart';

class AuthRepository {
  final GraphQLClient _client;

  AuthRepository(this._client);

  Future<User> validateApiKey() async {
    final result = await _client.query(
      QueryOptions(document: gql(viewerQuery)),
    );

    if (result.hasException) {
      throw result.exception!;
    }

    return User.fromGraphQL(result.data!['viewer'] as Map<String, dynamic>);
  }
}
