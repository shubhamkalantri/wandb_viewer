import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/run.dart';
import '../../../providers/run_detail_provider.dart';
import '../../../widgets/loading_indicator.dart';
import '../../../widgets/error_view.dart';
import '../widgets/metric_chart.dart';

class ChartsTab extends ConsumerStatefulWidget {
  final Run run;
  final RunDetailParams params;

  const ChartsTab({super.key, required this.run, required this.params});

  @override
  ConsumerState<ChartsTab> createState() => _ChartsTabState();
}

class _ChartsTabState extends ConsumerState<ChartsTab> {
  late Set<String> _selectedKeys;

  @override
  void initState() {
    super.initState();
    // Default: select up to first 5 metric keys
    final allKeys = widget.run.summaryMetrics.keys
        .where((k) => !k.startsWith('_'))
        .toList();
    _selectedKeys = allKeys.take(5).toSet();
  }

  @override
  Widget build(BuildContext context) {
    final allKeys = widget.run.summaryMetrics.keys
        .where((k) => !k.startsWith('_'))
        .toList();

    if (allKeys.isEmpty) {
      return const Center(child: Text('No metrics logged'));
    }

    if (_selectedKeys.isEmpty) {
      return const Center(child: Text('Select metrics to chart'));
    }

    final metricsAsync = ref.watch(runMetricsProvider((
      params: widget.params,
      keys: _selectedKeys.toList(),
    )));

    return Column(
      children: [
        // Metric selector chips
        Padding(
          padding: const EdgeInsets.all(8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: allKeys.map((key) {
                final selected = _selectedKeys.contains(key);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: Text(key),
                    selected: selected,
                    onSelected: (value) {
                      setState(() {
                        if (value) {
                          _selectedKeys.add(key);
                        } else {
                          _selectedKeys.remove(key);
                        }
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        // Chart
        Expanded(
          child: metricsAsync.when(
            loading: () => const LoadingIndicator(message: 'Loading metrics...'),
            error: (e, _) => ErrorView(
              message: 'Failed to load metrics. Check your connection and try again.',
              onRetry: () => ref.invalidate(runMetricsProvider((
                params: widget.params,
                keys: _selectedKeys.toList(),
              ))),
            ),
            data: (metrics) => Padding(
              padding: const EdgeInsets.all(8),
              child: MetricChart(metrics: metrics),
            ),
          ),
        ),
      ],
    );
  }
}
