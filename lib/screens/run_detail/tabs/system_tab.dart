import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../../models/system_metrics.dart';
import '../../../providers/run_detail_provider.dart';
import '../../../widgets/loading_indicator.dart';
import '../../../widgets/error_view.dart';

class SystemTab extends ConsumerWidget {
  final RunDetailParams params;
  const SystemTab({super.key, required this.params});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(runSystemMetricsProvider(params));

    return metricsAsync.when(
      loading: () => const LoadingIndicator(message: 'Loading system metrics...'),
      error: (e, _) => ErrorView(
        message: 'Failed to load system metrics: $e',
        onRetry: () => ref.invalidate(runSystemMetricsProvider(params)),
      ),
      data: (metrics) {
        if (metrics.points.isEmpty) {
          return const Center(child: Text('No system metrics available'));
        }

        // Group metrics by category
        final gpuKeys = metrics.availableKeys
            .where((k) => k.contains('gpu'))
            .toList()..sort();
        final cpuKeys = metrics.availableKeys
            .where((k) => k.contains('cpu'))
            .toList()..sort();
        final memKeys = metrics.availableKeys
            .where((k) => k.contains('memory') || k.contains('mem'))
            .toList()..sort();
        final otherKeys = metrics.availableKeys
            .where((k) => !gpuKeys.contains(k) && !cpuKeys.contains(k) && !memKeys.contains(k))
            .toList()..sort();

        return ListView(
          padding: const EdgeInsets.all(8),
          children: [
            if (gpuKeys.isNotEmpty)
              _SystemMetricChart(
                title: 'GPU',
                keys: gpuKeys,
                metrics: metrics,
              ),
            if (cpuKeys.isNotEmpty)
              _SystemMetricChart(
                title: 'CPU',
                keys: cpuKeys,
                metrics: metrics,
              ),
            if (memKeys.isNotEmpty)
              _SystemMetricChart(
                title: 'Memory',
                keys: memKeys,
                metrics: metrics,
              ),
            if (otherKeys.isNotEmpty)
              _SystemMetricChart(
                title: 'Other',
                keys: otherKeys,
                metrics: metrics,
              ),
          ],
        );
      },
    );
  }
}

class _SystemMetricChart extends StatelessWidget {
  final String title;
  final List<String> keys;
  final SystemMetrics metrics;

  const _SystemMetricChart({
    required this.title,
    required this.keys,
    required this.metrics,
  });

  String _shortKey(String key) {
    // Strip 'system.' prefix for readability
    return key.startsWith('system.') ? key.substring(7) : key;
  }

  @override
  Widget build(BuildContext context) {
    final firstTimestamp = metrics.points.isNotEmpty
        ? metrics.points.first.timestamp
        : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: SizedBox(
        height: 250,
        child: SfCartesianChart(
          title: ChartTitle(text: title),
          legend: const Legend(
            isVisible: true,
            position: LegendPosition.bottom,
            overflowMode: LegendItemOverflowMode.wrap,
          ),
          zoomPanBehavior: ZoomPanBehavior(
            enablePinching: true,
            enablePanning: true,
            zoomMode: ZoomMode.x,
          ),
          trackballBehavior: TrackballBehavior(
            enable: true,
            activationMode: ActivationMode.singleTap,
          ),
          primaryXAxis: NumericAxis(
            title: const AxisTitle(text: 'Time (s)'),
            numberFormat: null,
            labelFormat: '{value}s',
          ),
          primaryYAxis: const NumericAxis(),
          series: keys.map((key) {
            final data = metrics.points
                .where((p) => p.values.containsKey(key))
                .toList();
            return LineSeries<SystemMetricPoint, double>(
              name: _shortKey(key),
              dataSource: data,
              xValueMapper: (point, _) => point.timestamp - firstTimestamp,
              yValueMapper: (point, _) => point.values[key] ?? 0,
              animationDuration: 0,
            );
          }).toList(),
        ),
      ),
    );
  }
}
