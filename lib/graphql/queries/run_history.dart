String runHistoryQuery(List<String> metricKeys, int samples) {
  final specs = metricKeys
      .map((k) {
        final escaped = k.replaceAll(r'\', r'\\').replaceAll('"', r'\"');
        return '{key: "$escaped", samples: $samples}';
      })
      .join(', ');

  return '''
query RunHistory(\$project: String!, \$entity: String!, \$runName: String!) {
  project(name: \$project, entityName: \$entity) {
    run(name: \$runName) {
      sampledHistory(specs: [$specs])
    }
  }
}
''';
}

const String runEventsQuery = r'''
query RunEvents($project: String!, $entity: String!, $runName: String!, $samples: Int!) {
  project(name: $project, entityName: $entity) {
    run(name: $runName) {
      events(samples: $samples)
    }
  }
}
''';
