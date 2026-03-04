import 'package:flutter_test/flutter_test.dart';
import 'package:wandb_viewer/models/run.dart';

void main() {
  group('Run', () {
    test('fromGraphQL parses valid run data', () {
      final data = {
        'id': 'abc123',
        'name': 'run-id-1',
        'displayName': 'My Training Run',
        'state': 'running',
        'createdAt': '2026-03-01T10:00:00Z',
        'updatedAt': '2026-03-01T12:00:00Z',
        'heartbeatAt': '2026-03-01T12:00:00Z',
        'config': '{"learning_rate": 0.001, "batch_size": 32}',
        'summaryMetrics': '{"loss": 0.5, "accuracy": 0.85}',
        'tags': ['experiment-1'],
        'notes': 'Test run',
        'group': 'group-a',
        'jobType': 'train',
        'user': {'username': 'testuser'},
      };

      final run = Run.fromGraphQL(data);

      expect(run.id, 'abc123');
      expect(run.name, 'run-id-1');
      expect(run.displayName, 'My Training Run');
      expect(run.state, RunState.running);
      expect(run.config['learning_rate'], 0.001);
      expect(run.summaryMetrics['loss'], 0.5);
      expect(run.tags, ['experiment-1']);
      expect(run.username, 'testuser');
    });

    test('fromGraphQL handles null/missing fields gracefully', () {
      final data = {
        'id': 'abc123',
        'name': 'run-id-1',
        'state': 'finished',
        'config': null,
        'summaryMetrics': null,
        'tags': null,
        'user': null,
      };

      final run = Run.fromGraphQL(data);

      expect(run.config, isEmpty);
      expect(run.summaryMetrics, isEmpty);
      expect(run.tags, isEmpty);
      expect(run.username, isNull);
    });

    test('isActive returns true for running state', () {
      final run = Run.fromGraphQL({
        'id': '1', 'name': 'r', 'state': 'running',
      });
      expect(run.isActive, isTrue);
    });

    test('isActive returns false for finished state', () {
      final run = Run.fromGraphQL({
        'id': '1', 'name': 'r', 'state': 'finished',
      });
      expect(run.isActive, isFalse);
    });
  });
}
