class User {
  final String id;
  final String username;
  final String? email;
  final List<String> teams;

  const User({
    required this.id,
    required this.username,
    this.email,
    this.teams = const [],
  });

  factory User.fromGraphQL(Map<String, dynamic> data) {
    final teamEdges = data['teams']?['edges'] as List? ?? [];
    return User(
      id: data['id'] as String? ?? '',
      username: data['username'] as String? ?? '',
      email: data['email'] as String?,
      teams: teamEdges
          .whereType<Map<String, dynamic>>()
          .map((e) {
            final node = e['node'] as Map<String, dynamic>?;
            return node?['name'] as String?;
          })
          .whereType<String>()
          .toList(),
    );
  }
}
