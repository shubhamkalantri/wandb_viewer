const String runHistoryQuery = r'''
query RunHistory($project: String!, $entity: String!, $runName: String!, $specs: [JSONString!]!) {
  project(name: $project, entityName: $entity) {
    run(name: $runName) {
      sampledHistory(specs: $specs)
    }
  }
}
''';

const String runEventsQuery = r'''
query RunEvents($project: String!, $entity: String!, $runName: String!, $samples: Int) {
  project(name: $project, entityName: $entity) {
    run(name: $runName) {
      events(samples: $samples)
    }
  }
}
''';
