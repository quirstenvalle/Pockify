import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/auth_validation.dart';
import 'package:flutter_app/form_validation.dart';
import 'package:flutter_app/finance_models.dart';

void main() {
  group('auth validation', () {
    test('accepts password with capital first letter, 8+ chars, special char', () {
      expect(validatePassword('Password1!').ok, isTrue);
    });

    test('rejects password shorter than 8 characters', () {
      expect(validatePassword('Pass1!').ok, isFalse);
    });

    test('rejects password without leading capital letter', () {
      expect(validatePassword('password1!').ok, isFalse);
    });

    test('rejects password without special character', () {
      expect(validatePassword('Password1').ok, isFalse);
    });

    test('signup requires matching passwords', () {
      final result = validateSignup(
        name: 'Mark Santos',
        email: 'mark@example.com',
        password: 'Password1!',
        confirmPassword: 'Password2!',
        currency: 'PHP (₱)',
        employmentStatus: 'Student',
      );

      expect(result.ok, isFalse);
      expect(result.message, contains('match'));
    });
  });

  group('form validation', () {
    test('builds transaction from form input', () {
      final tx = buildTransaction(
        kind: TxKind.expense,
        amountText: '250',
        category: 'Food',
        dateText: '08/23/2026',
        note: 'Lunch',
      );

      expect(tx.amount, 250);
      expect(tx.date, '2026-08-23');
      expect(tx.note, 'Lunch');
    });

    test('filters transactions by query and date range', () {
      final txs = [
        TransactionModel(
          id: '1',
          kind: TxKind.expense,
          amount: 100,
          category: 'Food',
          date: DateTime.now().toIso8601String().substring(0, 10),
          note: 'Lunch',
        ),
        TransactionModel(
          id: '2',
          kind: TxKind.income,
          amount: 5000,
          category: 'Salary',
          date: '2020-01-01',
          note: 'Old pay',
        ),
      ];

      final filtered = filterTransactions(
        txs,
        query: 'lunch',
        filter: 'This Month',
      );

      expect(filtered.length, 1);
      expect(filtered.first.id, '1');
    });
  });
}
