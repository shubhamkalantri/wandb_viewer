import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/run.dart';
import '../../runs/run_card.dart';
import '../widgets/config_table.dart';

class OverviewTab extends StatelessWidget {
  final Run run;
  const OverviewTab({super.key, required this.run});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Status
        Row(
          children: [
            Text('Status: ', style: theme.textTheme.titleSmall),
            RunStateBadge(state: run.state),
          ],
        ),
        const SizedBox(height: 16),

        // Summary Metrics
        if (run.summaryMetrics.isNotEmpty) ...[
          Text('Summary Metrics', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: run.summaryMetrics.entries.map((e) {
              final value = e.value is num
                  ? (e.value as num).toStringAsFixed(6)
                  : e.value.toString();
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.key, style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      )),
                      const SizedBox(height: 4),
                      Text(value, style: theme.textTheme.titleMedium?.copyWith(
                        fontFamily: 'monospace',
                      )),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],

        // Config
        ConfigTable(config: run.config),
        const SizedBox(height: 8),

        // Tags
        if (run.tags.isNotEmpty) ...[
          Text('Tags', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: run.tags
                .map((t) => Chip(label: Text(t)))
                .toList(),
          ),
          const SizedBox(height: 16),
        ],

        // Notes
        if (run.notes != null && run.notes!.isNotEmpty) ...[
          Text('Notes', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(run.notes!),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Run Info
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Run Info', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                if (run.username != null)
                  _InfoRow(label: 'User', value: run.username!),
                if (run.group != null)
                  _InfoRow(label: 'Group', value: run.group!),
                if (run.jobType != null)
                  _InfoRow(label: 'Job Type', value: run.jobType!),
                _InfoRow(label: 'Run ID', value: run.name),
                if (run.createdAt != null)
                  _InfoRow(
                    label: 'Created',
                    value: DateFormat.yMMMd().add_Hm().format(run.createdAt!),
                  ),
                if (run.updatedAt != null)
                  _InfoRow(
                    label: 'Updated',
                    value: DateFormat.yMMMd().add_Hm().format(run.updatedAt!),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}
