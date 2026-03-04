import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/project.dart';

class ProjectCard extends StatelessWidget {
  final Project project;
  final VoidCallback onTap;

  const ProjectCard({super.key, required this.project, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(project.name),
        subtitle: Text(project.description ?? 'No description'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('${project.runCount} runs',
                style: Theme.of(context).textTheme.bodySmall),
            if (project.updatedAt != null)
              Text(DateFormat.yMMMd().format(project.updatedAt!),
                  style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
