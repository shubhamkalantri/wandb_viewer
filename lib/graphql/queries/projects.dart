const String projectsQuery = r'''
query Projects($entity: String!, $first: Int!, $cursor: String) {
  models(entityName: $entity, first: $first, after: $cursor) {
    edges {
      node {
        id
        name
        description
        createdAt
        updatedAt
        runCount
      }
      cursor
    }
    pageInfo {
      hasNextPage
      endCursor
    }
  }
}
''';
