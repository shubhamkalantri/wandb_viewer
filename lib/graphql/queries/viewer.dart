const String viewerQuery = r'''
query Viewer {
  viewer {
    id
    username
    email
    teams {
      edges {
        node {
          name
        }
      }
    }
  }
}
''';
