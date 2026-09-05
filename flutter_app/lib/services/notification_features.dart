import '../finance_models.dart';
import '../settings/app_settings.dart';

/// Returns true when the user has logged at least one expense today.
bool hasExpenseLoggedToday(List<TransactionModel> txs, [DateTime? now]) {
  final today = (now ?? DateTime.now()).toIso8601String().substring(0, 10);
  return txs.any((tx) => tx.kind == TxKind.expense && tx.date == today);
}

/// Message for the daily expense reminder, or null when none is needed.
String? dailyExpenseReminderMessage({
  required bool enabled,
  required List<TransactionModel> txs,
  required String? lastShownIsoDate,
  DateTime? now,
}) {
  if (!enabled) return null;
  final today = (now ?? DateTime.now()).toIso8601String().substring(0, 10);
  if (lastShownIsoDate == today) return null;
  if (hasExpenseLoggedToday(txs, now)) return null;
  return 'Reminder: you haven\'t logged any expenses today. '
      'A quick entry keeps your budget accurate.';
}

/// Alerts only when the budget-threshold setting is on.
List<AlertModel> activeBudgetAlerts({
  required bool enabled,
  required List<TransactionModel> txs,
  required List<BudgetModel> budgets,
}) {
  if (!enabled) return const [];
  return budgetAlerts(txs, budgets);
}

/// Alerts that crossed a threshold and have not been surfaced yet.
List<AlertModel> newBudgetThresholdAlerts({
  required bool enabled,
  required List<TransactionModel> txs,
  required List<BudgetModel> budgets,
  required Set<String> alreadyNotifiedIds,
}) {
  return activeBudgetAlerts(
    enabled: enabled,
    txs: txs,
    budgets: budgets,
  ).where((alert) => !alreadyNotifiedIds.contains(alert.id)).toList();
}

/// Milestone days newly reached that still need a celebration.
List<int> pendingStreakCelebrations({
  required bool enabled,
  required int streak,
  required Set<int> alreadyCelebrated,
}) {
  if (!enabled || streak <= 0) return const [];
  return streakMilestones
      .where((m) => streak >= m && !alreadyCelebrated.contains(m))
      .toList();
}

bool isStreakAchievementUnlocked(int streak, int milestoneDays) =>
    streak >= milestoneDays;
