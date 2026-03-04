import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPrefsProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Override in main.dart with actual instance');
});

class SettingsState {
  final Duration pollInterval;
  final bool notificationsEnabled;

  const SettingsState({
    this.pollInterval = const Duration(seconds: 30),
    this.notificationsEnabled = true,
  });

  SettingsState copyWith({
    Duration? pollInterval,
    bool? notificationsEnabled,
  }) {
    return SettingsState(
      pollInterval: pollInterval ?? this.pollInterval,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, SettingsState>(SettingsNotifier.new);

class SettingsNotifier extends Notifier<SettingsState> {
  static const _pollKey = 'poll_interval_seconds';
  static const _notifKey = 'notifications_enabled';

  @override
  SettingsState build() {
    final prefs = ref.read(sharedPrefsProvider);
    return SettingsState(
      pollInterval: Duration(seconds: prefs.getInt(_pollKey) ?? 30),
      notificationsEnabled: prefs.getBool(_notifKey) ?? true,
    );
  }

  Future<void> setPollInterval(Duration interval) async {
    final prefs = ref.read(sharedPrefsProvider);
    await prefs.setInt(_pollKey, interval.inSeconds);
    state = state.copyWith(pollInterval: interval);
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = ref.read(sharedPrefsProvider);
    await prefs.setBool(_notifKey, enabled);
    state = state.copyWith(notificationsEnabled: enabled);
  }
}
