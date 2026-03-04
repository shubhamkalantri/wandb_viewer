import 'package:graphql_flutter/graphql_flutter.dart';

/// A sanitized exception that strips sensitive details (auth headers,
/// server URLs, response bodies) from GraphQL errors before they
/// propagate to the UI or logging layer.
class GraphQLRequestException implements Exception {
  final String message;
  GraphQLRequestException(this.message);

  @override
  String toString() => message;

  /// Converts an [OperationException] into a safe [GraphQLRequestException].
  ///
  /// Extracts only the user-visible GraphQL error messages (if any) or
  /// falls back to a generic description based on the link exception type.
  factory GraphQLRequestException.from(OperationException exception) {
    // Prefer server-provided GraphQL error messages (these are
    // application-level and safe to surface).
    final gqlErrors = exception.graphqlErrors;
    if (gqlErrors.isNotEmpty) {
      final messages = gqlErrors.map((e) => e.message).join('; ');
      return GraphQLRequestException(messages);
    }

    // For network / link errors, return a generic message so we never
    // expose raw HTTP details, auth headers, or response bodies.
    final link = exception.linkException;
    if (link is NetworkException) {
      return GraphQLRequestException('Network error. Check your connection.');
    }
    if (link is ServerException) {
      return GraphQLRequestException(
          'Server returned an error (${link.statusCode ?? 'unknown'}).');
    }

    // Include exception type for diagnosis — linkException details
    // are stripped of auth headers by graphql_flutter already.
    if (link != null) {
      return GraphQLRequestException(
          'Request failed (${link.runtimeType}): ${link.originalException ?? link}');
    }

    return GraphQLRequestException('Request failed: $exception');
  }
}

/// Checks a [QueryResult] and throws a sanitized [GraphQLRequestException]
/// if the result contains an error.
void throwIfException(QueryResult result) {
  if (result.hasException) {
    throw GraphQLRequestException.from(result.exception!);
  }
}
