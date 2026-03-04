import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../core/constants.dart';
import '../models/user.dart';
import '../repositories/auth_repository.dart';

final secureStorageProvider = Provider((_) => const FlutterSecureStorage());

final authStateProvider =
    AsyncNotifierProvider<AuthNotifier, User?>(AuthNotifier.new);

class AuthNotifier extends AsyncNotifier<User?> {

  @override
  Future<User?> build() async {
    final storage = ref.read(secureStorageProvider);
    final savedKey = await storage.read(key: AppConstants.apiKeyStorageKey);
    if (savedKey == null) return null;

    try {
      return await _validateKey(savedKey);
    } catch (_) {
      await storage.delete(key: AppConstants.apiKeyStorageKey);
      return null;
    }
  }

  Future<User> login(String apiKey) async {
    final user = await _validateKey(apiKey);
    final storage = ref.read(secureStorageProvider);
    await storage.write(key: AppConstants.apiKeyStorageKey, value: apiKey);
    state = AsyncData(user);
    return user;
  }

  Future<void> logout() async {
    final storage = ref.read(secureStorageProvider);
    await storage.delete(key: AppConstants.apiKeyStorageKey);
    state = const AsyncData(null);
  }

  Future<User> _validateKey(String apiKey) {
    final httpLink = HttpLink(AppConstants.wandbGraphqlUrl);
    final credentials = base64Encode(utf8.encode('api:$apiKey'));
    final authLink = AuthLink(getToken: () => 'Basic $credentials');
    final client = GraphQLClient(
      link: authLink.concat(httpLink),
      cache: GraphQLCache(),
    );
    return AuthRepository(client).validateApiKey();
  }
}

// Provider for the current API key (read from storage)
final apiKeyProvider = FutureProvider<String?>((ref) async {
  final storage = ref.read(secureStorageProvider);
  return storage.read(key: AppConstants.apiKeyStorageKey);
});

// Provider for the authenticated GraphQL client
final authenticatedClientProvider = FutureProvider<GraphQLClient?>((ref) async {
  final apiKey = await ref.watch(apiKeyProvider.future);
  if (apiKey == null) return null;

  final httpLink = HttpLink(AppConstants.wandbGraphqlUrl);
  final credentials = base64Encode(utf8.encode('api:$apiKey'));
  final authLink = AuthLink(getToken: () => 'Basic $credentials');
  return GraphQLClient(
    link: authLink.concat(httpLink),
    cache: GraphQLCache(),
  );
});
