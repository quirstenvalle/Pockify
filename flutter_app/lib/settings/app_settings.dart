/// User preference toggles for in-app reminders and celebrations.
class AppSettings {
  final bool dailyExpenseReminder;
  final bool budgetThresholdAlerts;
  final bool streakCelebrations;
  final bool biometricLock;

  const AppSettings({
    this.dailyExpenseReminder = true,
    this.budgetThresholdAlerts = true,
    this.streakCelebrations = true,
    this.biometricLock = false,
  });

  static const dailyExpenseReminderLabel = 'Daily expense reminder';
  static const budgetThresholdAlertsLabel = 'Budget threshold alerts';
  static const streakCelebrationsLabel = 'Streak celebrations';
  static const biometricLockLabel = 'Biometric lock';

  static const labels = [
    dailyExpenseReminderLabel,
    budgetThresholdAlertsLabel,
    streakCelebrationsLabel,
    biometricLockLabel,
  ];

  bool valueFor(String label) {
    switch (label) {
      case dailyExpenseReminderLabel:
        return dailyExpenseReminder;
      case budgetThresholdAlertsLabel:
        return budgetThresholdAlerts;
      case streakCelebrationsLabel:
        return streakCelebrations;
      case biometricLockLabel:
        return biometricLock;
      default:
        return false;
    }
  }

  AppSettings copyWith({
    bool? dailyExpenseReminder,
    bool? budgetThresholdAlerts,
    bool? streakCelebrations,
    bool? biometricLock,
  }) {
    return AppSettings(
      dailyExpenseReminder:
          dailyExpenseReminder ?? this.dailyExpenseReminder,
      budgetThresholdAlerts:
          budgetThresholdAlerts ?? this.budgetThresholdAlerts,
      streakCelebrations: streakCelebrations ?? this.streakCelebrations,
      biometricLock: biometricLock ?? this.biometricLock,
    );
  }

  AppSettings withLabel(String label, bool value) {
    switch (label) {
      case dailyExpenseReminderLabel:
        return copyWith(dailyExpenseReminder: value);
      case budgetThresholdAlertsLabel:
        return copyWith(budgetThresholdAlerts: value);
      case streakCelebrationsLabel:
        return copyWith(streakCelebrations: value);
      case biometricLockLabel:
        return copyWith(biometricLock: value);
      default:
        return this;
    }
  }

  Map<String, dynamic> toJson() => {
        'dailyExpenseReminder': dailyExpenseReminder,
        'budgetThresholdAlerts': budgetThresholdAlerts,
        'streakCelebrations': streakCelebrations,
        'biometricLock': biometricLock,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      dailyExpenseReminder: json['dailyExpenseReminder'] as bool? ?? true,
      budgetThresholdAlerts: json['budgetThresholdAlerts'] as bool? ?? true,
      streakCelebrations: json['streakCelebrations'] as bool? ?? true,
      biometricLock: json['biometricLock'] as bool? ?? false,
    );
  }
}

/// Streak day counts that unlock achievements / celebrations.
const streakMilestones = [3, 7, 14, 30];

String streakMilestoneTitle(int days) {
  switch (days) {
    case 3:
      return 'Smart Starter';
    case 7:
      return 'Budget Keeper';
    case 14:
      return 'Wise Spender';
    case 30:
      return 'Financial Master';
    default:
      return '$days-day streak';
  }
}
