import 'auth_validation.dart';
import 'finance_models.dart';

ValidationResult validateAmount(String raw) {
  final amount = double.tryParse(raw.trim());
  if (amount == null || amount <= 0) {
    return const ValidationResult.invalid('Enter a valid amount greater than 0.');
  }
  return const ValidationResult.valid();
}

ValidationResult validateBudgetInput({
  required String category,
  required String limitText,
}) {
  if (category.trim().isEmpty) {
    return const ValidationResult.invalid('Choose a budget category.');
  }
  return validateAmount(limitText);
}

ValidationResult validateGoalInput({
  required String title,
  required String targetText,
}) {
  if (title.trim().isEmpty) {
    return const ValidationResult.invalid('Add a goal name.');
  }
  return validateAmount(targetText);
}

BudgetModel buildBudget({
  required String category,
  required String limitText,
}) {
  final limit = double.parse(limitText.trim());
  return BudgetModel(
    id: DateTime.now().microsecondsSinceEpoch.toString(),
    category: category.trim(),
    limit: limit,
  );
}

GoalModel buildGoal({
  required String title,
  required String targetText,
}) {
  final target = double.parse(targetText.trim());
  return GoalModel(
    id: DateTime.now().microsecondsSinceEpoch.toString(),
    title: title.trim(),
    target: target,
    current: 0,
  );
}

TransactionModel buildTransaction({
  required TxKind kind,
  required String amountText,
  required String category,
  required String dateText,
  String? note,
  String method = 'Cash',
}) {
  final amount = double.parse(amountText.trim());
  return TransactionModel(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    kind: kind,
    amount: amount,
    category: category,
    note: note?.trim().isEmpty ?? true ? null : note!.trim(),
    date: parseDisplayDate(dateText),
    method: method,
  );
}

String parseDisplayDate(String input) {
  final parts = input.trim().split('/');
  if (parts.length != 3) return todayIso();
  return '${parts[2]}-${parts[0].padLeft(2, '0')}-${parts[1].padLeft(2, '0')}';
}

bool matchesTransactionFilter(TransactionModel tx, String filter) {
  final age = DateTime.now().difference(DateTime.parse(tx.date)).inDays;
  return switch (filter) {
    'Today' => age == 0,
    'This Week' => age <= 7,
    'This Month' => age <= 31,
    _ => true,
  };
}

bool matchesTransactionQuery(TransactionModel tx, String query) {
  final normalized = query.trim().toLowerCase();
  if (normalized.isEmpty) return true;
  return '${tx.category} ${tx.note ?? ''}'.toLowerCase().contains(normalized);
}

List<TransactionModel> filterTransactions(
  List<TransactionModel> transactions, {
  required String query,
  required String filter,
}) {
  return transactions
      .where(
        (tx) =>
            matchesTransactionQuery(tx, query) &&
            matchesTransactionFilter(tx, filter),
      )
      .toList()
    ..sort((a, b) => b.date.compareTo(a.date));
}

GoalModel contributeToGoal(GoalModel goal, {double amount = 500}) {
  return GoalModel(
    id: goal.id,
    title: goal.title,
    target: goal.target,
    current: (goal.current + amount).clamp(0, goal.target),
  );
}
