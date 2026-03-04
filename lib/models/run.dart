import 'dart:convert';

enum RunState { running, finished, crashed, failed, killed, unknown }

class Run {
  final String id;
  final String name;
  final String? displayName;
  final RunState state;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? heartbeatAt;
  final Map<String, dynamic> config;
  final Map<String, dynamic> summaryMetrics;
  final List<String> tags;
  final String? notes;
  final String? group;
  final String? jobType;
  final String? username;

  const Run({
    required this.id,
    required this.name,
    this.displayName,
    required this.state,
    this.createdAt,
    this.updatedAt,
    this.heartbeatAt,
    this.config = const {},
    this.summaryMetrics = const {},
    this.tags = const [],
    this.notes,
    this.group,
    this.jobType,
    this.username,
  });

  bool get isActive => state == RunState.running;

  static RunState _parseState(String? state) {
    switch (state) {
      case 'running': return RunState.running;
      case 'finished': return RunState.finished;
      case 'crashed': return RunState.crashed;
      case 'failed': return RunState.failed;
      case 'killed': return RunState.killed;
      default: return RunState.unknown;
    }
  }

  static Map<String, dynamic> _parseJsonString(String? jsonStr) {
    if (jsonStr == null || jsonStr.isEmpty) return {};
    try {
      return json.decode(jsonStr) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  factory Run.fromGraphQL(Map<String, dynamic> data) {
    return Run(
      id: data['id'] as String? ?? '',
      name: data['name'] as String? ?? '',
      displayName: data['displayName'] as String?,
      state: _parseState(data['state'] as String?),
      createdAt: data['createdAt'] != null
          ? DateTime.tryParse(data['createdAt'] as String)
          : null,
      updatedAt: data['updatedAt'] != null
          ? DateTime.tryParse(data['updatedAt'] as String)
          : null,
      heartbeatAt: data['heartbeatAt'] != null
          ? DateTime.tryParse(data['heartbeatAt'] as String)
          : null,
      config: _parseJsonString(data['config'] as String?),
      summaryMetrics: _parseJsonString(data['summaryMetrics'] as String?),
      tags: (data['tags'] as List?)?.cast<String>() ?? [],
      notes: data['notes'] as String?,
      group: data['group'] as String?,
      jobType: data['jobType'] as String?,
      username: (data['user'] as Map?)?['username'] as String?,
    );
  }
}
