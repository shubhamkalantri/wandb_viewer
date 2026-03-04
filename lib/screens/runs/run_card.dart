import 'package:flutter/material.dart';
import '../../models/run.dart';

class RunStateBadge extends StatelessWidget {
  final RunState state;
  const RunStateBadge({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (state) {
      RunState.running => (Colors.green, 'Running'),
      RunState.finished => (Colors.blue, 'Finished'),
      RunState.crashed => (Colors.red, 'Crashed'),
      RunState.failed => (Colors.red, 'Failed'),
      RunState.killed => (Colors.orange, 'Killed'),
      RunState.unknown => (Colors.grey, 'Unknown'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class RunCard extends StatelessWidget {
  final Run run;
  final VoidCallback onTap;
  final bool selected;
  final VoidCallback? onLongPress;

  const RunCard({
    super.key,
    required this.run,
    required this.onTap,
    this.selected = false,
    this.onLongPress,
  });

  String _formatElapsed() {
    if (run.createdAt == null) return '';
    final elapsed = DateTime.now().difference(run.createdAt!);
    if (elapsed.inDays > 0) return '${elapsed.inDays}d ${elapsed.inHours % 24}h';
    if (elapsed.inHours > 0) return '${elapsed.inHours}h ${elapsed.inMinutes % 60}m';
    return '${elapsed.inMinutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Pick up to 3 summary metrics to show
    final topMetrics = run.summaryMetrics.entries.take(3).toList();

    return Card(
      color: selected ? theme.colorScheme.primaryContainer : null,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      run.displayName ?? run.name,
                      style: theme.textTheme.titleSmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  RunStateBadge(state: run.state),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    run.name,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  if (run.createdAt != null)
                    Text(
                      _formatElapsed(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
              if (topMetrics.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  children: topMetrics.map((e) {
                    final value = e.value is num
                        ? (e.value as num).toStringAsFixed(4)
                        : e.value.toString();
                    return Text(
                      '${e.key}: $value',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
