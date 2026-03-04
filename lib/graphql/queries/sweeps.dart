const String sweepsQuery = r'''
query Sweeps($project: String!, $entity: String!, $first: Int!, $cursor: String) {
  project(name: $project, entityName: $entity) {
    sweeps(first: $first, after: $cursor) {
      edges {
        node {
          id
          name
          state
          runCount
          bestLoss
          config
          createdAt
          updatedAt
        }
        cursor
      }
      pageInfo {
        hasNextPage
        endCursor
      }
    }
  }
}
''';
