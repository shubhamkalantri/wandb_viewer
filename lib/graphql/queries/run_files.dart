const String runFilesQuery = r'''
query RunFiles($project: String!, $entity: String!, $runName: String!, $first: Int!) {
  project(name: $project, entityName: $entity) {
    run(name: $runName) {
      files(first: $first) {
        edges {
          node {
            name
            directUrl
            url(upload: false)
            sizeBytes
            updatedAt
          }
        }
      }
    }
  }
}
''';
