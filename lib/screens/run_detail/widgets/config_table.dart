import 'package:flutter/material.dart';

class ConfigTable extends StatefulWidget {
  final Map<String, dynamic> config;
  final String title;

  const ConfigTable({super.key, required this.config, this.title = 'Config'});

  @override
  State<ConfigTable> createState() => _ConfigTableState();
}

class _ConfigTableState extends State<ConfigTable> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.config.isEmpty) return const SizedBox.shrink();

    final entries = widget.config.entries.toList();
    final theme = Theme.of(context);

    return Card(
      child: Column(
        children: [
          ListTile(
            title: Text(widget.title, style: theme.textTheme.titleSmall),
            trailing: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
            onTap: () => setState(() => _expanded = !_expanded),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
              child: Table(
                columnWidths: const {
                  0: FlexColumnWidth(2),
                  1: FlexColumnWidth(3),
                },
                children: entries.map((e) {
                  final value = e.value is Map || e.value is List
                      ? e.value.toString()
                      : '${e.value}';
                  return TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          e.key,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          value,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
