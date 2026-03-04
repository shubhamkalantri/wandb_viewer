class MetricPoint {
  final int step;
  final double value;
  final double? timestamp;

  const MetricPoint({
    required this.step,
    required this.value,
    this.timestamp,
  });
}

class MetricHistory {
  final String key;
  final List<MetricPoint> points;

  const MetricHistory({required this.key, required this.points});

  factory MetricHistory.fromSampledHistory(
      String key, List<Map<String, dynamic>> rows) {
    final points = <MetricPoint>[];
    for (final row in rows) {
      final value = row[key];
      if (value != null && value is num) {
        points.add(MetricPoint(
          step: (row['_step'] as num?)?.toInt() ?? points.length,
          value: value.toDouble(),
          timestamp: (row['_timestamp'] as num?)?.toDouble(),
        ));
      }
    }
    return MetricHistory(key: key, points: points);
  }
}
