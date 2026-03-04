import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../models/metric_history.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/run_repository.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_view.dart';

/// Provider that fetches metric history for multiple runs
final compareMetricsProvider = FutureProvider.family<
    Map<String, List<MetricHistory>>,
    ({String entity, String project, List<String> runNames, List<String> keys})>(
  (ref, args) async {
    final client = await ref.read(authenticatedClientProvider.future);
    if (client == null) throw Exception('Not authenticated');
    final repo = RunRepository(client);

    final entries = await Future.wait(
      args.runNames.map((runName) async {
        final metrics = await repo.getMetricHistory(
          args.entity, args.project, runName, args.keys,
        );
        return MapEntry(runName, metrics);
      }),
    );
    return Map.fromEntries(entries);
  },
);

class CompareRunsScreen extends ConsumerStatefulWidget {
  final String entity;
  final String project;
  final List<String> runNames;

  const CompareRunsScreen({
    super.key,
    required this.entity,
    required this.project,
    required this.runNames,
  });

  @override
  ConsumerState<CompareRunsScreen> createState() => _CompareRunsScreenState();
}

class _CompareRunsScreenState extends ConsumerState<CompareRunsScreen> {
  String? _selectedMetric;
  List<String> _availableMetrics = [];
  bool _metricsDetected = false;

  @override
  void initState() {
    super.initState();
    _detectMetrics();
  }

  Future<void> _detectMetrics() async {
    if (widget.runNames.isEmpty) {
      if (mounted) setState(() => _metricsDetected = true);
      return;
    }
    // Fetch run details to get available metric keys
    try {
      final client = await ref.read(authenticatedClientProvider.future);
      if (client == null) return;
      final repo = RunRepository(client);
      final run = await repo.getRunDetail(
        widget.entity,
        widget.project,
        widget.runNames.first,
      );
      final keys = run.summaryMetrics.keys
          .where((k) => !k.startsWith('_'))
          .toList()
        ..sort();
      if (mounted) {
        setState(() {
          _availableMetrics = keys;
          _selectedMetric = keys.isNotEmpty ? keys.first : null;
          _metricsDetected = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _metricsDetected = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_metricsDetected) {
      return const Scaffold(
        body: LoadingIndicator(message: 'Detecting metrics...'),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Compare (${widget.runNames.length} runs)'),
      ),
      body: Column(
        children: [
          // Metric selector
          if (_availableMetrics.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _availableMetrics.map((key) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(key),
                        selected: _selectedMetric == key,
                        onSelected: (_) =>
                            setState(() => _selectedMetric = key),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

          // Chart
          if (_selectedMetric != null)
            Expanded(child: _CompareChart(
              entity: widget.entity,
              project: widget.project,
              runNames: widget.runNames,
              metricKey: _selectedMetric!,
            ))
          else
            const Expanded(
              child: Center(child: Text('No metrics available to compare')),
            ),

          // Summary table
          if (_selectedMetric != null)
            _SummaryTable(
              entity: widget.entity,
              project: widget.project,
              runNames: widget.runNames,
              metricKey: _selectedMetric!,
            ),
        ],
      ),
    );
  }
}

class _CompareChart extends ConsumerWidget {
  final String entity;
  final String project;
  final List<String> runNames;
  final String metricKey;

  const _CompareChart({
    required this.entity,
    required this.project,
    required this.runNames,
    required this.metricKey,
  });

  static const _colors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.amber,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(compareMetricsProvider((
      entity: entity,
      project: project,
      runNames: runNames,
      keys: [metricKey],
    )));

    return metricsAsync.when(
      loading: () => const LoadingIndicator(message: 'Loading metrics...'),
      error: (e, _) => const ErrorView(message: 'Failed to load metrics. Check your connection and try again.'),
      data: (allMetrics) {
        final series = <LineSeries<MetricPoint, num>>[];
        var colorIdx = 0;

        for (final runName in runNames) {
          final metrics = allMetrics[runName];
          if (metrics == null || metrics.isEmpty) continue;
          final history = metrics.first;

          series.add(LineSeries<MetricPoint, num>(
            name: runName,
            dataSource: history.points,
            xValueMapper: (p, _) => p.step,
            yValueMapper: (p, _) => p.value,
            color: _colors[colorIdx % _colors.length],
            animationDuration: 0,
          ));
          colorIdx++;
        }

        return Padding(
          padding: const EdgeInsets.all(8),
          child: SfCartesianChart(
            title: ChartTitle(text: metricKey),
            legend: const Legend(
              isVisible: true,
              position: LegendPosition.bottom,
              overflowMode: LegendItemOverflowMode.wrap,
            ),
            zoomPanBehavior: ZoomPanBehavior(
              enablePinching: true,
              enablePanning: true,
              enableDoubleTapZooming: true,
              zoomMode: ZoomMode.x,
            ),
            trackballBehavior: TrackballBehavior(
              enable: true,
              activationMode: ActivationMode.singleTap,
            ),
            primaryXAxis: const NumericAxis(
              title: AxisTitle(text: 'Step'),
            ),
            primaryYAxis: const NumericAxis(),
            series: series,
          ),
        );
      },
    );
  }
}

class _SummaryTable extends ConsumerWidget {
  final String entity;
  final String project;
  final List<String> runNames;
  final String metricKey;

  const _SummaryTable({
    required this.entity,
    required this.project,
    required this.runNames,
    required this.metricKey,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(compareMetricsProvider((
      entity: entity,
      project: project,
      runNames: runNames,
      keys: [metricKey],
    )));

    return metricsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (allMetrics) {
        return Container(
          margin: const EdgeInsets.all(8),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Final Values',
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  ...runNames.map((name) {
                    final metrics = allMetrics[name];
                    final lastValue = (metrics != null &&
                            metrics.isNotEmpty &&
                            metrics.first.points.isNotEmpty)
                        ? metrics.first.points.last.value.toStringAsFixed(6)
                        : 'N/A';
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(name,
                                style: Theme.of(context).textTheme.bodySmall),
                          ),
                          Text(lastValue,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(fontFamily: 'monospace')),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
