import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../../models/metric_history.dart';

class MetricChart extends StatelessWidget {
  final List<MetricHistory> metrics;
  final String? title;

  const MetricChart({super.key, required this.metrics, this.title});

  @override
  Widget build(BuildContext context) {
    if (metrics.isEmpty) {
      return const Center(child: Text('No metric data'));
    }

    return SfCartesianChart(
      title: ChartTitle(text: title ?? ''),
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
        tooltipSettings: const InteractiveTooltip(
          format: 'point.x : point.y',
        ),
      ),
      primaryXAxis: const NumericAxis(
        title: AxisTitle(text: 'Step'),
      ),
      primaryYAxis: const NumericAxis(),
      series: metrics.map((metric) {
        return LineSeries<MetricPoint, num>(
          name: metric.key,
          dataSource: metric.points,
          xValueMapper: (point, _) => point.step,
          yValueMapper: (point, _) => point.value,
          animationDuration: 0,
        );
      }).toList(),
    );
  }
}
