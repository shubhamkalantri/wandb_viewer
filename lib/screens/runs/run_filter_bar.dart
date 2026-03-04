import 'package:flutter/material.dart';

enum RunFilter { active, all }

class RunFilterBar extends StatelessWidget {
  final RunFilter current;
  final ValueChanged<RunFilter> onChanged;

  const RunFilterBar({
    super.key,
    required this.current,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SegmentedButton<RunFilter>(
        segments: const [
          ButtonSegment(value: RunFilter.active, label: Text('Active')),
          ButtonSegment(value: RunFilter.all, label: Text('All')),
        ],
        selected: {current},
        onSelectionChanged: (selection) => onChanged(selection.first),
      ),
    );
  }
}
