import 'package:flutter/material.dart';

class PollStatusIndicator extends StatelessWidget {
  final bool isPolling;
  final Duration interval;

  const PollStatusIndicator({
    super.key,
    required this.isPolling,
    required this.interval,
  });

  @override
  Widget build(BuildContext context) {
    if (!isPolling) return const SizedBox.shrink();
    return Tooltip(
      message: 'Auto-refreshing every ${interval.inSeconds}s',
      child: Icon(
        Icons.sync,
        size: 16,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
