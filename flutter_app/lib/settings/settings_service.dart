import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'app_settings.dart';

/// Persists notification preference toggles and one-shot reminder state.
class SettingsService {
  SettingsService._();
  static final SettingsService instance = SettingsService._();

  static const _settingsKey = 'pockify_app_settings_v1';
  static const _reminderShownKey = 'pockify_daily_reminder_shown_v1';
  static const _celebratedStreaksKey = 'pockify_celebrated_streaks_v1';
  static const _notifiedAlertsKey = 'pockify_notified_budget_alerts_v1';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<AppSettings> load() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_settingsKey);
    if (raw == null || raw.isEmpty) return const AppSettings();
    try {
      return AppSettings.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {
      return const AppSettings();
    }
  }

  Future<void> save(AppSettings settings) async {
    final prefs = await _prefs;
    await prefs.setString(_settingsKey, jsonEncode(settings.toJson()));
  }

  /// ISO date (yyyy-MM-dd) when the daily reminder was last shown.
  Future<String?> lastDailyReminderShownDate() async {
    final prefs = await _prefs;
    return prefs.getString(_reminderShownKey);
  }

  Future<void> markDailyReminderShown(String isoDate) async {
    final prefs = await _prefs;
    await prefs.setString(_reminderShownKey, isoDate);
  }

  Future<Set<int>> celebratedStreakMilestones() async {
    final prefs = await _prefs;
    final list = prefs.getStringList(_celebratedStreaksKey) ?? const [];
    return list.map(int.parse).toSet();
  }

  Future<void> markStreakMilestoneCelebrated(int days) async {
    final prefs = await _prefs;
    final current = await celebratedStreakMilestones();
    current.add(days);
    await prefs.setStringList(
      _celebratedStreaksKey,
      current.map((e) => e.toString()).toList()..sort(),
    );
  }

  Future<Set<String>> notifiedAlertIds() async {
    final prefs = await _prefs;
    return (prefs.getStringList(_notifiedAlertsKey) ?? const []).toSet();
  }

  Future<void> markAlertsNotified(Iterable<String> ids) async {
    final prefs = await _prefs;
    final current = await notifiedAlertIds();
    current.addAll(ids);
    await prefs.setStringList(_notifiedAlertsKey, current.toList());
  }
}
