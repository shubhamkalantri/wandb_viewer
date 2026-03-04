const String runDetailQuery = r'''
query RunDetail($project: String!, $entity: String!, $runName: String!) {
  project(name: $project, entityName: $entity) {
    run(name: $runName) {
      id
      name
      displayName
      state
      config
      summaryMetrics
      tags
      notes
      createdAt
      updatedAt
      heartbeatAt
      group
      jobType
      systemMetrics
      user { username }
      runInfo {
        gpu
        gpuCount
        os
        program
        python
        cpuCount
      }
    }
  }
}
''';
