const String runsQuery = r'''
query Runs($project: String!, $entity: String!, $first: Int!, $cursor: String, $filters: JSONString, $order: String) {
  project(name: $project, entityName: $entity) {
    runs(first: $first, after: $cursor, filters: $filters, order: $order) {
      edges {
        node {
          id
          name
          displayName
          state
          createdAt
          updatedAt
          heartbeatAt
          config
          summaryMetrics
          tags
          notes
          group
          jobType
          user {
            username
          }
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
