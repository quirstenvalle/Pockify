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

    test('same-category budgets use separate date periods', () {
      final txs = [
        TransactionModel(
          id: '1',
          kind: TxKind.expense,
          amount: 1000,
          category: 'Shopping',
          date: '2026-09-23',
        ),
      ];
      final budgets = [
        BudgetModel(
          id: 'old',
          category: 'Shopping',
          limit: 1000,
          date: '2026-09-23',
        ),
        BudgetModel(
          id: 'new',
          category: 'Shopping',
          limit: 1000,
          date: '2026-09-26',
        ),
      ];

      expect(
        spentForBudget(budget: budgets[0], budgets: budgets, txs: txs),
        1000,
      );
      expect(spentForBudget(budget: budgets[1], budgets: budgets, txs: txs), 0);
    });

    test('only unconsumed same-name budgets block a new budget', () {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final budget = BudgetModel(
        id: 'active',
        name: 'Food',
        category: 'Food',
        limit: 1000,
        period: 'Monthly',
        date: today,
      );
      final transaction = TransactionModel(
        id: 'expense',
        kind: TxKind.expense,
        amount: 100,
        category: 'Food',
        date: today,
      );

      expect(
        hasUnconsumedBudget(
          name: 'Food',
          budgets: [budget],
          txs: [transaction],
        ),
        isTrue,
      );
      expect(
        hasUnconsumedBudget(
          name: 'Food',
          budgets: [budget],
          txs: [transaction.copyWith(amount: 1000)],
        ),
        isFalse,
      );

      final renewedBudget = BudgetModel(
        id: 'renewed',
        name: 'Food',
        category: 'Food',
        limit: 1000,
        date: DateTime.now()
            .add(const Duration(days: 1))
            .toIso8601String()
            .substring(0, 10),
      );
      expect(
        spentForBudget(
          budget: renewedBudget,
          budgets: [budget, renewedBudget],
          txs: [transaction.copyWith(amount: 1000)],
        ),
        0,
      );
      final renewedTransaction = transaction.copyWith(
        amount: 250,
        date: renewedBudget.date,
      );
      expect(
        spentForBudget(
          budget: budget,
          budgets: [budget, renewedBudget],
          txs: [transaction, renewedTransaction],
        ),
        100,
      );
      expect(
        spentForBudget(
          budget: renewedBudget,
          budgets: [budget, renewedBudget],
          txs: [transaction, renewedTransaction],
        ),
        250,
      );

      expect(
        hasUnconsumedBudget(
          name: 'Food',
          budgets: [
            BudgetModel(
              id: 'active-weekly',
              name: 'Food',
              category: 'Food',
              limit: 1000,
              period: 'Weekly',
              date: today,
            ),
          ],
          txs: [transaction],
        ),
        isTrue,
      );
    });

    test('duplicate budget names receive the next available suffix', () {
      final budgets = [
        BudgetModel(id: 'grocery', name: 'Grocery', category: 'Food', limit: 1),
        BudgetModel(
          id: 'grocery1',
          name: 'Grocery1',
          category: 'Food',
          limit: 1,
        ),
        BudgetModel(id: 'rent', name: 'Rent', category: 'Bills', limit: 1),
      ];

      expect(nextAvailableBudgetName('Grocery', budgets), 'Grocery2');
      expect(nextAvailableBudgetName('Rent', budgets), 'Rent1');
      expect(nextAvailableBudgetName('Transport', budgets), 'Transport');
    });

    test(
      'budget totals use transaction budget IDs for duplicate categories',
      () {
        final budgets = [
          BudgetModel(
            id: 'grocery',
            name: 'Grocery',
            category: 'Grocery',
            limit: 1000,
          ),
          BudgetModel(
            id: 'grocery1',
            name: 'Grocery1',
            category: 'Grocery',
            limit: 1000,
          ),
        ];
        final transactions = [
          TransactionModel(
            id: 'old-expense',
            budgetId: 'grocery',
            kind: TxKind.expense,
            amount: 1000,
            category: 'Grocery',
            date: todayIso(),
          ),
          TransactionModel(
            id: 'new-expense',
            budgetId: 'grocery1',
            kind: TxKind.expense,
            amount: 200,
            category: 'Grocery',
            date: todayIso(),
          ),
        ];

        expect(
          spentForBudget(
            budget: budgets[0],
            budgets: budgets,
            txs: transactions,
          ),
          1000,
        );
        expect(
          spentForBudget(
            budget: budgets[1],
            budgets: budgets,
            txs: transactions,
          ),
          200,
        );
      },
    );

    test('transaction payload omits budget_id when it is not assigned', () {
      final tx = TransactionModel(
        id: 'tx-1',
        kind: TxKind.expense,
        amount: 120,
        category: 'Food',
        date: todayIso(),
      );

      final payload = tx.toSupabase();

      expect(payload.containsKey('budget_id'), isFalse);
      expect(payload['category'], 'Food');
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
