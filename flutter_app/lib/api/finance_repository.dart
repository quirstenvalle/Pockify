import 'package:supabase_flutter/supabase_flutter.dart';

import '../finance_models.dart';

/// Loads and saves Pockify finance data in Supabase (RLS per user).
class FinanceRepository {
  FinanceRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String? get _userId => _client.auth.currentUser?.id;

  Future<List<TransactionModel>> loadTransactions() async {
    final userId = _userId;
    if (userId == null) return [];

    final rows = await _client
        .from('transactions')
        .select()
        .eq('user_id', userId)
        .order('date', ascending: false)
        .order('created_at', ascending: false);

    return (rows as List)
        .map(
          (row) =>
              TransactionModel.fromSupabase(Map<String, dynamic>.from(row)),
        )
        .toList();
  }

  Future<List<BudgetModel>> loadBudgets() async {
    final userId = _userId;
    if (userId == null) return [];

    final rows = await _client
        .from('budgets')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: true);

    return (rows as List)
        .map((row) => BudgetModel.fromSupabase(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<List<GoalModel>> loadGoals() async {
    final userId = _userId;
    if (userId == null) return [];

    final rows = await _client
        .from('goals')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: true);

    return (rows as List)
        .map((row) => GoalModel.fromSupabase(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<void> upsertTransaction(TransactionModel tx) async {
    final userId = _userId;
    if (userId == null) throw StateError('Not signed in');

    final payload = {...tx.toSupabase(), 'user_id': userId};

    try {
      await _client.from('transactions').upsert(payload);
    } on PostgrestException catch (error) {
      if (error.code == 'PGRST204' &&
          payload.containsKey('budget_id') &&
          error.message.contains("'budget_id'")) {
        final fallback = Map<String, dynamic>.from(payload)
          ..remove('budget_id');
        await _client.from('transactions').upsert(fallback);
        return;
      }
      rethrow;
    }
  }

  Future<void> deleteTransaction(String id) async {
    final userId = _userId;
    if (userId == null) return;
    await _client
        .from('transactions')
        .delete()
        .eq('id', id)
        .eq('user_id', userId);
  }

  Future<void> upsertBudget(BudgetModel budget) async {
    final userId = _userId;
    if (userId == null) throw StateError('Not signed in');

    await _client.from('budgets').upsert({
      ...budget.toSupabase(),
      'user_id': userId,
    });
  }

  Future<void> deleteBudget(String id) async {
    final userId = _userId;
    if (userId == null) return;
    await _client.from('budgets').delete().eq('id', id).eq('user_id', userId);
  }

  Future<void> upsertGoal(GoalModel goal) async {
    final userId = _userId;
    if (userId == null) throw StateError('Not signed in');

    await _client.from('goals').upsert({
      ...goal.toSupabase(),
      'user_id': userId,
    });
  }

  Future<void> addGoalContribution({
    required String goalId,
    required double amount,
    String? date,
  }) async {
    final userId = _userId;
    if (userId == null) throw StateError('Not signed in');

    await _client.from('goal_contributions').insert({
      'goal_id': goalId,
      'user_id': userId,
      'amount': amount,
      'contributed_at': date ?? todayIso(),
    });
  }

  Future<void> deleteGoal(String id) async {
    final userId = _userId;
    if (userId == null) return;
    await _client.from('goals').delete().eq('id', id).eq('user_id', userId);
  }
}
