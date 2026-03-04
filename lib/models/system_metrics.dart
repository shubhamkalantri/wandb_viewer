class SystemMetricPoint {
  final double timestamp;
  final Map<String, double> values;

  const SystemMetricPoint({required this.timestamp, required this.values});
}

class SystemMetrics {
  final List<SystemMetricPoint> points;
  final Set<String> availableKeys;

  const SystemMetrics({required this.points, required this.availableKeys});

  factory SystemMetrics.fromEvents(List<dynamic> events) {
    final points = <SystemMetricPoint>[];
    final keys = <String>{};

    for (final event in events) {
      if (event is! Map<String, dynamic>) continue;
      final ts = (event['_timestamp'] as num?)?.toDouble();
      if (ts == null) continue;

      final values = <String, double>{};
      event.forEach((k, v) {
        if (k.startsWith('system.') && v is num) {
          values[k] = v.toDouble();
          keys.add(k);
        }
      });

      if (values.isNotEmpty) {
        points.add(SystemMetricPoint(timestamp: ts, values: values));
      }
    }
    return SystemMetrics(points: points, availableKeys: keys);
  }
}
