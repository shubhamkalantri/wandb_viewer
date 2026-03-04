class Sweep {
  final String id;
  final String name;
  final String? state;
  final int runCount;
  final double? bestLoss;
  final String? config;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Sweep({
    required this.id,
    required this.name,
    this.state,
    this.runCount = 0,
    this.bestLoss,
    this.config,
    this.createdAt,
    this.updatedAt,
  });

  factory Sweep.fromGraphQL(Map<String, dynamic> data) {
    return Sweep(
      id: data['id'] as String? ?? '',
      name: data['name'] as String? ?? '',
      state: data['state'] as String?,
      runCount: data['runCount'] as int? ?? 0,
      bestLoss: (data['bestLoss'] as num?)?.toDouble(),
      config: data['config'] as String?,
      createdAt: data['createdAt'] != null
          ? DateTime.tryParse(data['createdAt'] as String)
          : null,
      updatedAt: data['updatedAt'] != null
          ? DateTime.tryParse(data['updatedAt'] as String)
          : null,
    );
  }
}
