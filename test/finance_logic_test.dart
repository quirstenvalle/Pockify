import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/finance_models.dart';

void main() {
  group('Pockify finance logic', () {
    test('monthly totals include income, expenses and balance', () {
      final txs = [
        TransactionModel(
          id: '1',
          kind: TxKind.income,
          amount: 20000,
          category: 'Salary',
          date: DateTime.now().toIso8601String().substring(0, 10),
        ),
        TransactionModel(
          id: '2',
          kind: TxKind.expense,
          amount: 5000,
          category: 'Food',
          date: DateTime.now().toIso8601String().substring(0, 10),
        ),
      ];

      final totals = monthlyTotals(txs);

      expect(totals.income, 20000);
      expect(totals.expenses, 5000);
      expect(totals.balance, 15000);
    });

    test('budget alerts detect over-budget and near-limit categories', () {
      final txs = [
        TransactionModel(
          id: '1',
          kind: TxKind.expense,
          amount: 600,
          category: 'Food',
          date: DateTime.now().toIso8601String().substring(0, 10),
        ),
        TransactionModel(
          id: '2',
          kind: TxKind.expense,
          amount: 300,
          category: 'Transportation',
          date: DateTime.now().toIso8601String().substring(0, 10),
        ),
      ];

      final budgets = [
        BudgetModel(id: 'b1', category: 'Food', limit: 500),
        BudgetModel(id: 'b2', category: 'Transportation', limit: 250),
      ];

      final alerts = budgetAlerts(txs, budgets);

      expect(
        alerts.any(
          (a) =>
              (a.level == 'warn' || a.level == 'over') &&
              a.title.contains('Food'),
        ),
        isTrue,
      );
      expect(
        alerts.any(
          (a) => a.level == 'over' && a.title.contains('Transportation'),
        ),
        isTrue,
      );
    });

    test('health score stays within valid range', () {
      final txs = SEED_TRANSACTIONS;
      final budgets = SEED_BUDGETS;

      final score = healthScore(txs, budgets);

      expect(score >= 0, isTrue);
      expect(score <= 100, isTrue);
    });
  });
}
