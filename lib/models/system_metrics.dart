import 'dart:convert';

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
      // W&B API may return events as JSON strings or pre-parsed Maps
      Map<String, dynamic>? eventMap;
      if (event is Map<String, dynamic>) {
        eventMap = event;
      } else if (event is String) {
        try {
          eventMap = json.decode(event) as Map<String, dynamic>;
        } catch (_) {
          continue;
        }
      }
      if (eventMap == null) continue;

      final ts = (eventMap['_timestamp'] as num?)?.toDouble();
      if (ts == null) continue;

      final values = <String, double>{};
      eventMap.forEach((k, v) {
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
