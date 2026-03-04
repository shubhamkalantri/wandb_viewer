class Project {
  final String id;
  final String name;
  final String entityName;
  final String? description;
  final int runCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Project({
    required this.id,
    required this.name,
    required this.entityName,
    this.description,
    this.runCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory Project.fromGraphQL(Map<String, dynamic> data, String entityName) {
    return Project(
      id: data['id'] as String? ?? '',
      name: data['name'] as String? ?? '',
      entityName: entityName,
      description: data['description'] as String?,
      runCount: data['runCount'] as int? ?? 0,
      createdAt: data['createdAt'] != null
          ? DateTime.tryParse(data['createdAt'] as String)
          : null,
      updatedAt: data['updatedAt'] != null
          ? DateTime.tryParse(data['updatedAt'] as String)
          : null,
    );
  }
}
