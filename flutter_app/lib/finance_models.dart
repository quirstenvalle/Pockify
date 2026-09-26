import 'data/countries.dart';

enum TxKind { income, expense }

class TransactionModel {
  final String id;
  final TxKind kind;
  final double amount;
  final String category;
  final String? budgetId;
  final String? note;
  final String date;
  final String? method;
  final bool favorite;

  TransactionModel({
    required this.id,
    required this.kind,
    required this.amount,
    required this.category,
    this.budgetId,
    this.note,
    required this.date,
    this.method,
    this.favorite = false,
  });

  TransactionModel copyWith({
    TxKind? kind,
    double? amount,
    String? category,
    String? budgetId,
    String? note,
    String? date,
    String? method,
    bool? favorite,
  }) {
    return TransactionModel(
      id: id,
      kind: kind ?? this.kind,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      budgetId: budgetId ?? this.budgetId,
      note: note ?? this.note,
      date: date ?? this.date,
      method: method ?? this.method,
      favorite: favorite ?? this.favorite,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind.name,
    'amount': amount,
    'category': category,
    'budget_id': budgetId,
    'note': note,
    'date': date,
    'method': method,
    'favorite': favorite,
  };

  Map<String, dynamic> toSupabase() {
    final payload = <String, dynamic>{
      'id': id,
      'kind': kind.name,
      'amount': amount,
      'category': category,
      'note': note,
      'date': date,
      'method': method,
      'favorite': favorite,
    };

    if (budgetId != null) {
      payload['budget_id'] = budgetId;
    }

    return payload;
  }

  factory TransactionModel.fromJson(Map<String, dynamic> json) =>
      TransactionModel(
        id: json['id'] as String,
        kind: TxKind.values.firstWhere(
          (kind) => kind.name == json['kind'],
          orElse: () => TxKind.expense,
        ),
        amount: (json['amount'] as num).toDouble(),
        category: json['category'] as String,
        budgetId: json['budget_id'] as String?,
        note: json['note'] as String?,
        date: json['date'] as String,
        method: json['method'] as String?,
        favorite: json['favorite'] as bool? ?? false,
      );
  factory TransactionModel.fromSupabase(Map<String, dynamic> json) =>
      TransactionModel.fromJson({
        ...json,
        'date': '${json['date']}'.substring(0, 10),
        'amount': json['amount'],
      });
}

class CategoryModel {
  final String name;
  final String icon;
  final String color;
  final bool essential;
  final bool isDefault;

  const CategoryModel({
    required this.name,
    required this.icon,
    required this.color,
    required this.essential,
    required this.isDefault,
  });
}

class BudgetModel {
  final String id;
  final String name;
  final String category;
  final double limit;
  final String period; // 'Daily' | 'Weekly' | 'Monthly' | 'Yearly'
  final String? _date;

  String get date => _date ?? todayIso();

  BudgetModel({
    required this.id,
    this.name = '',
    required this.category,
    required this.limit,
    this.period = 'Monthly',
    this._date,
  });

  Map<String, dynamic> toSupabase() => {
    'id': id,
    'name': name,
    'category': category,
    'limit_amount': limit,
    'period': period,
    'budget_date': date,
  };

  factory BudgetModel.fromSupabase(Map<String, dynamic> json) {
    final rawDate = json['budget_date'] ?? json['created_at'];
    return BudgetModel(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? '',
      category: json['category'] as String,
      limit: (json['limit_amount'] as num).toDouble(),
      period: (json['period'] as String?) ?? 'Monthly',
      date: rawDate == null ? null : '$rawDate'.substring(0, 10),
    );
  }
}

class GoalModel {
  final String id;
  final String title;
  final double target;
  final double current;
  final bool isRecurring;
  final double? recurringAmount;
  final String? recurringFrequency;

  GoalModel({
    required this.id,
    required this.title,
    required this.target,
    required this.current,
    this.isRecurring = false,
    this.recurringAmount,
    this.recurringFrequency,
  });

  Map<String, dynamic> toSupabase() => {
    'id': id,
    'title': title,
    'target_amount': target,
    'current_amount': current,
    'is_recurring': isRecurring,
    'recurring_amount': recurringAmount,
    'recurring_frequency': recurringFrequency,
  };

  factory GoalModel.fromSupabase(Map<String, dynamic> json) => GoalModel(
    id: json['id'] as String,
    title: json['title'] as String,
    target: (json['target_amount'] as num).toDouble(),
    current: (json['current_amount'] as num).toDouble(),
    isRecurring: json['is_recurring'] as bool? ?? false,
    recurringAmount: (json['recurring_amount'] as num?)?.toDouble(),
    recurringFrequency: json['recurring_frequency'] as String?,
  );
}

String _activeCurrencySymbol = '₱';

/// Sets the currency symbol used by [peso] app-wide, derived from the
/// signed-in user's country/currency selection.
void setActiveCurrency(String? currencyValue) {
  _activeCurrencySymbol = currencySymbolForCurrency(currencyValue);
}

String peso(num value) =>
    '$_activeCurrencySymbol${value.toStringAsFixed(value % 1 == 0 ? 0 : 2)}';

const List<CategoryModel> CATEGORIES = [
  CategoryModel(
    name: 'Food',
    icon: '🍜',
    color: '#F59E0B',
    essential: false,
    isDefault: true,
  ),
  CategoryModel(
    name: 'Transportation',
    icon: '🚌',
    color: '#3B82F6',
    essential: true,
    isDefault: true,
  ),
  CategoryModel(
    name: 'Grocery',
    icon: '🛒',
    color: '#10B981',
    essential: true,
    isDefault: true,
  ),
  CategoryModel(
    name: 'Shopping',
    icon: '🛍️',
    color: '#8B5CF6',
    essential: false,
    isDefault: true,
  ),
  CategoryModel(
    name: 'Entertainment',
    icon: '🎬',
    color: '#EC4899',
    essential: false,
    isDefault: true,
  ),
  CategoryModel(
    name: 'Bills',
    icon: '🧾',
    color: '#F97316',
    essential: true,
    isDefault: true,
  ),
  CategoryModel(
    name: 'Healthcare',
    icon: '💊',
    color: '#14B8A6',
    essential: true,
    isDefault: true,
  ),
  CategoryModel(
    name: 'Education',
    icon: '📚',
    color: '#6366F1',
    essential: true,
    isDefault: true,
  ),
  CategoryModel(
    name: 'Savings',
    icon: '🏦',
    color: '#22C55E',
    essential: true,
    isDefault: true,
  ),
  CategoryModel(
    name: 'Coffee',
    icon: '☕',
    color: '#F59E0B',
    essential: false,
    isDefault: false,
  ),
  CategoryModel(
    name: 'Pet Expenses',
    icon: '🐶',
    color: '#A78BFA',
    essential: false,
    isDefault: false,
  ),
  CategoryModel(
    name: 'Others',
    icon: '✨',
    color: '#94A3B8',
    essential: false,
    isDefault: true,
  ),
];

String todayIso() => DateTime.now().toIso8601String().substring(0, 10);

double sumTransactions(List<TransactionModel> list) =>
    list.fold(0, (total, item) => total + item.amount);

bool isThisMonth(String iso) =>
    iso.substring(0, 7) == DateTime.now().toIso8601String().substring(0, 7);

class MonthlyTotals {
  final double income;
  final double expenses;
  final double balance;

  MonthlyTotals({
    required this.income,
    required this.expenses,
    required this.balance,
  });
}

MonthlyTotals monthlyTotals(List<TransactionModel> txs) {
  final month = txs.where((x) => isThisMonth(x.date)).toList();
  final income = sumTransactions(
    month.where((x) => x.kind == TxKind.income).toList(),
  );
  final expenses = sumTransactions(
    month.where((x) => x.kind == TxKind.expense).toList(),
  );
  return MonthlyTotals(
    income: income,
    expenses: expenses,
    balance: income - expenses,
  );
}

Map<String, double> spentByCategory(List<TransactionModel> txs) {
  final map = <String, double>{};
  for (final tx in txs.where(
    (x) => x.kind == TxKind.expense && isThisMonth(x.date),
  )) {
    map[tx.category] = (map[tx.category] ?? 0) + tx.amount;
  }
  return map;
}

class BudgetWindow {
  final DateTime start;
  final DateTime end; // exclusive: the moment the budget resets

  const BudgetWindow(this.start, this.end);

  String get startIso => start.toIso8601String().substring(0, 10);
  String get endIso => end.toIso8601String().substring(0, 10);
}

DateTime _clampedDate(int year, int month, int day) {
  final first = DateTime(year, month, 1);
  final lastDay = DateTime(first.year, first.month + 1, 0).day;
  return DateTime(first.year, first.month, day > lastDay ? lastDay : day);
}

DateTime _shiftPeriod(DateTime anchor, String period, int count) {
  switch (period) {
    case 'Daily':
      return DateTime(anchor.year, anchor.month, anchor.day + count);
    case 'Weekly':
      return DateTime(anchor.year, anchor.month, anchor.day + 7 * count);
    case 'Yearly':
      return _clampedDate(anchor.year + count, anchor.month, anchor.day);
    default:
      return _clampedDate(anchor.year, anchor.month + count, anchor.day);
  }
}

BudgetWindow budgetWindow(BudgetModel budget, [DateTime? now]) {
  final current = now ?? DateTime.now();
  final today = DateTime(current.year, current.month, current.day);
  final parsed = DateTime.tryParse(budget.date) ?? today;
  final anchor = DateTime(parsed.year, parsed.month, parsed.day);
  var n = 0;
  while (!_shiftPeriod(anchor, budget.period, n + 1).isAfter(today)) {
    n++;
  }
  return BudgetWindow(
    _shiftPeriod(anchor, budget.period, n),
    _shiftPeriod(anchor, budget.period, n + 1),
  );
}

double spentForBudget({
  required BudgetModel budget,
  required List<BudgetModel> budgets,
  required List<TransactionModel> txs,
}) {
  final window = budgetWindow(budget);
  final budgetIdentity =
      (budget.name.trim().isEmpty ? budget.category : budget.name)
          .trim()
          .toLowerCase();
  final budgetStart = DateTime.tryParse(budget.date) ?? window.start;
  DateTime? nextBudgetStart;
  for (final candidate in budgets) {
    final candidateIdentity =
        (candidate.name.trim().isEmpty ? candidate.category : candidate.name)
            .trim()
            .toLowerCase();
    if (candidate.category != budget.category ||
        candidateIdentity != budgetIdentity) {
      continue;
    }
    final candidateStart = DateTime.tryParse(candidate.date);
    if (candidateStart == null || !candidateStart.isAfter(budgetStart)) {
      continue;
    }
    if (nextBudgetStart == null || candidateStart.isBefore(nextBudgetStart)) {
      nextBudgetStart = candidateStart;
    }
  }
  final end = nextBudgetStart != null && nextBudgetStart.isBefore(window.end)
      ? nextBudgetStart
      : window.end;
  var total = 0.0;
  for (final tx in txs) {
    if (tx.budgetId != null) {
      if (tx.budgetId == budget.id) total += tx.amount;
      continue;
    }
    if (tx.kind != TxKind.expense || tx.category != budget.category) continue;
    final d = DateTime.tryParse(tx.date);
    if (d != null &&
        !d.isBefore(window.start) &&
        !d.isBefore(budgetStart) &&
        d.isBefore(end)) {
      total += tx.amount;
    }
  }
  return total;
}

bool hasUnconsumedBudget({
  required String name,
  required List<BudgetModel> budgets,
  required List<TransactionModel> txs,
}) {
  final identity = name.trim().toLowerCase();
  return budgets.any((budget) {
    final budgetIdentity =
        (budget.name.trim().isEmpty ? budget.category : budget.name)
            .trim()
            .toLowerCase();
    if (budgetIdentity != identity) return false;
    final spent = spentForBudget(budget: budget, budgets: budgets, txs: txs);
    return spent < budget.limit;
  });
}

String nextAvailableBudgetName(
  String requestedName,
  List<BudgetModel> budgets,
) {
  final requested = requestedName.trim();
  final existing = budgets
      .map(
        (budget) => (budget.name.trim().isEmpty ? budget.category : budget.name)
            .trim()
            .toLowerCase(),
      )
      .toSet();
  if (!existing.contains(requested.toLowerCase())) return requested;

  var suffix = 1;
  while (existing.contains('$requested$suffix'.toLowerCase())) {
    suffix++;
  }
  return '$requested$suffix';
}

class ChartPoint {
  final String label;
  final double amount;

  const ChartPoint({required this.label, required this.amount});
}

/// Month expenses grouped into Week 1–4 by day-of-month.
List<ChartPoint> weeklyBars(List<TransactionModel> txs) {
  final weeks = List<double>.filled(4, 0);
  for (final tx in txs.where(
    (x) => x.kind == TxKind.expense && isThisMonth(x.date),
  )) {
    final day = int.tryParse(tx.date.substring(8, 10)) ?? 1;
    final idx = ((day - 1) ~/ 7).clamp(0, 3);
    weeks[idx] += tx.amount;
  }
  return [
    for (var i = 0; i < weeks.length; i++)
      ChartPoint(label: 'Week ${i + 1}', amount: weeks[i]),
  ];
}

/// Last 6 calendar months of expense totals (demo fill for empty past months).
List<ChartPoint> monthlyTrend(List<TransactionModel> txs) {
  const demoBase = [6200.0, 7400.0, 5100.0, 8300.0, 6900.0];
  final out = <ChartPoint>[];
  final now = DateTime.now();

  for (var i = 5; i >= 0; i--) {
    final dt = DateTime(now.year, now.month - i, 1);
    final key =
        '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}';
    final amount = sumTransactions(
      txs
          .where((x) => x.kind == TxKind.expense && x.date.startsWith(key))
          .toList(),
    );
    final demoIndex = 5 - i;
    out.add(
      ChartPoint(
        label: _shortMonth(dt.month),
        amount: amount > 0
            ? amount
            : (demoIndex < demoBase.length ? demoBase[demoIndex] : 0),
      ),
    );
  }
  return out;
}

String _shortMonth(int month) {
  const names = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return names[(month - 1).clamp(0, 11)];
}

List<double> balanceSparkline(List<TransactionModel> txs, {int points = 12}) {
  final sorted = [...txs]..sort((a, b) => a.date.compareTo(b.date));
  if (sorted.isEmpty) {
    return List<double>.generate(points, (i) => 50 + (i.isEven ? 12.0 : -8.0));
  }

  var running = 0.0;
  final balances = <double>[];
  for (final tx in sorted) {
    running += tx.kind == TxKind.income ? tx.amount : -tx.amount;
    balances.add(running);
  }

  if (balances.length == 1) {
    return List<double>.filled(points, balances.first);
  }

  final step = (balances.length - 1) / (points - 1);
  return [
    for (var i = 0; i < points; i++)
      balances[(i * step).round().clamp(0, balances.length - 1)],
  ];
}

CategoryModel categoryOf(String name) => CATEGORIES.firstWhere(
  (category) => category.name == name,
  orElse: () => const CategoryModel(
    name: 'Others',
    icon: '✨',
    color: '#94A3B8',
    essential: false,
    isDefault: false,
  ),
);

class AlertModel {
  final String id;
  final String level;
  final String title;
  final String body;

  AlertModel({
    required this.id,
    required this.level,
    required this.title,
    required this.body,
  });
}

List<String> smartSuggestions(
  List<TransactionModel> txs,
  List<BudgetModel> budgets,
) {
  final totals = monthlyTotals(txs);
  final spent = spentByCategory(txs);
  final week = txs
      .where(
        (x) =>
            x.kind == TxKind.expense &&
            DateTime.now().difference(DateTime.parse(x.date)).inDays <= 7,
      )
      .toList();
  final suggestions = <String>[];

  if (totals.balance < 0) {
    suggestions.add(
      'Your monthly balance is ${peso(totals.balance.abs())} below zero. Pause non-essential spending until income catches up.',
    );
  }

  for (final budget in budgets) {
    final used = spentForBudget(budget: budget, budgets: budgets, txs: txs);
    if (used > budget.limit) {
      suggestions.add(
        '${budget.category} is ${peso(used - budget.limit)} over budget. Keep the next ${budget.category.toLowerCase()} purchase below the limit.',
      );
    }
  }

  final coffee = week.where((x) => x.category == 'Coffee').toList();
  if (coffee.length >= 2) {
    suggestions.add(
      'You\'ve bought coffee ${coffee.length} times this week. Making coffee at home twice next week could save around ${peso(((coffee.fold<double>(0, (sum, item) => sum + item.amount) / coffee.length) * 2).roundToDouble())}.',
    );
  }

  final transport = week
      .where((x) => x.category == 'Transportation')
      .fold<double>(0, (sum, item) => sum + item.amount);
  if (transport > 150) {
    suggestions.add(
      'Transportation reached ${peso(transport)} this week. Walking short distances could trim it noticeably.',
    );
  }

  final food = week
      .where((x) => x.category == 'Food')
      .fold<double>(0, (sum, item) => sum + item.amount);
  if (food > 0) {
    suggestions.add(
      'Food spending this week reached ${peso(food)}. Planning meals ahead can lower it quickly.',
    );
  }

  return suggestions.take(3).toList();
}

String? dailyFinancialInsight(
  List<TransactionModel> txs,
  List<BudgetModel> budgets,
) {
  final totals = monthlyTotals(txs);
  final spent = spentByCategory(txs);
  final candidates = <String>[];

  if (totals.balance < 0) {
    candidates.add(
      'Your spending is ${peso(totals.balance.abs())} higher than your income this month. Review your largest categories today.',
    );
  }

  for (final budget in budgets) {
    final used = spentForBudget(budget: budget, budgets: budgets, txs: txs);
    final remaining = budget.limit - used;
    if (remaining >= 0 && budget.limit > 0 && used / budget.limit >= 0.8) {
      candidates.add(
        '${budget.category} has ${peso(remaining)} left in its budget. Check the remaining amount before spending more.',
      );
    }
  }

  if (totals.balance > 0 && totals.income > 0) {
    candidates.add(
      'You have ${peso(totals.balance)} left after this month\'s expenses. Consider assigning part of it to a savings goal.',
    );
  }

  if (candidates.isEmpty) return null;
  return candidates[DateTime.now().day % candidates.length];
}

List<AlertModel> budgetAlerts(
  List<TransactionModel> txs,
  List<BudgetModel> budgets,
) {
  final alerts = <AlertModel>[];

  for (final budget in budgets) {
    final used = spentForBudget(budget: budget, budgets: budgets, txs: txs);
    final window = budgetWindow(budget);
    final pct = budget.limit == 0 ? 0.0 : used / budget.limit;

    if (pct >= 1) {
      alerts.add(
        AlertModel(
          id: 'budget-${budget.id}-${window.startIso}-over',
          level: 'over',
          title: 'You exceeded your ${budget.category} budget',
          body:
              '${peso(used)} of ${peso(budget.limit)} used — ${peso(used - budget.limit)} over the limit.',
        ),
      );
    } else if (pct >= 0.8) {
      alerts.add(
        AlertModel(
          id: 'budget-${budget.id}-${window.startIso}-warn',
          level: 'warn',
          title: '${budget.category} budget at ${((pct * 100).round())}%',
          body:
              '${peso(used)} of ${peso(budget.limit)} used. Only ${peso(budget.limit - used)} remaining.',
        ),
      );
    }
  }

  return alerts;
}

int unreadAlertCount(List<AlertModel> alerts, Set<String> readIds) =>
    alerts.where((alert) => !readIds.contains(alert.id)).length;

int essentialStreak(List<TransactionModel> txs) {
  var streak = 0;
  for (var i = 0; i < 60; i++) {
    final day = DateTime.now().subtract(Duration(days: i));
    final iso = day.toIso8601String().substring(0, 10);
    final dayTx = txs
        .where((x) => x.kind == TxKind.expense && x.date == iso)
        .toList();

    if (dayTx.isEmpty) {
      if (i == 0) continue;
      break;
    }

    if (dayTx.every((x) => categoryOf(x.category).essential)) {
      streak++;
    } else {
      break;
    }
  }
  return streak;
}

int healthScore(List<TransactionModel> txs, List<BudgetModel> budgets) {
  if (txs.isEmpty && budgets.isEmpty) {
    // Nothing set up yet — nothing to have overspent on.
    return 100;
  }

  if (budgets.isEmpty) {
    // No budget to measure against yet, so there's nothing to be over.
    return 100;
  }

  final perBudgetScores = <double>[];

  for (final budget in budgets) {
    if (budget.limit <= 0) continue;

    final spent = spentForBudget(budget: budget, budgets: budgets, txs: txs);
    final ratio = spent / budget.limit;

    if (ratio <= 1) {
      // Within (or exactly at) the limit: the more headroom left in this
      // budget's period, the higher the score. Right at the limit still
      // scores high rather than dropping.
      perBudgetScores.add(100 - 10 * ratio);
    } else {
      // Over the limit: the further past it, the lower the score.
      final over = ratio - 1;
      perBudgetScores.add((90 - 40 * over).clamp(0, 100));
    }
  }

  if (perBudgetScores.isEmpty) {
    // Budgets exist but none has a usable limit — nothing to score against.
    return 100;
  }

  final average =
      perBudgetScores.reduce((a, b) => a + b) / perBudgetScores.length;
  return average.round().clamp(0, 100);
}

final List<BudgetModel> SEED_BUDGETS = [
  BudgetModel(id: 'b1', category: 'Food', limit: 5000),
  BudgetModel(id: 'b2', category: 'Transportation', limit: 4000),
  BudgetModel(id: 'b3', category: 'Grocery', limit: 3500),
  BudgetModel(id: 'b4', category: 'Shopping', limit: 2000),
  BudgetModel(id: 'b5', category: 'Coffee', limit: 600),
  BudgetModel(id: 'b6', category: 'Entertainment', limit: 1200),
];

final List<GoalModel> SEED_GOALS = [
  GoalModel(id: 'g1', title: 'Emergency fund', target: 50000, current: 23000),
  GoalModel(id: 'g2', title: 'Travel fund', target: 30000, current: 14500),
  GoalModel(id: 'g3', title: 'Birthday gift', target: 8000, current: 3500),
];

List<TransactionModel> createSeedTransactions() {
  final now = DateTime.now();
  TransactionModel tx(
    String id,
    TxKind kind,
    double amount,
    String category,
    int offset, {
    String? note,
    bool favorite = false,
  }) {
    final date = now.subtract(Duration(days: offset));
    return TransactionModel(
      id: id,
      kind: kind,
      amount: amount,
      category: category,
      note: note,
      date: date.toIso8601String().substring(0, 10),
      method: kind == TxKind.income ? 'Bank' : 'Cash',
      favorite: favorite,
    );
  }

  return [
    tx('seed-1', TxKind.income, 20000, 'Salary', 12, note: 'December salary'),
    tx('seed-2', TxKind.income, 3500, 'Freelance', 8, note: 'Logo design'),
    tx(
      'seed-3',
      TxKind.expense,
      80,
      'Transportation',
      0,
      note: 'Bus fare',
      favorite: true,
    ),
    tx('seed-4', TxKind.expense, 900, 'Grocery', 0, note: 'Weekly groceries'),
    tx('seed-5', TxKind.expense, 1500, 'Bills', 1, note: 'Electricity'),
    tx('seed-6', TxKind.expense, 340, 'Healthcare', 2, note: 'Vitamins'),
    tx('seed-7', TxKind.expense, 220, 'Education', 3, note: 'Notebook + pens'),
    tx('seed-8', TxKind.expense, 130, 'Transportation', 4, note: 'Grab ride'),
    tx('seed-9', TxKind.expense, 720, 'Grocery', 5, note: 'Pantry restock'),
    tx('seed-10', TxKind.expense, 250, 'Food', 6, note: 'Lunch with team'),
    tx('seed-11', TxKind.expense, 95, 'Coffee', 6, note: 'Cold brew'),
    tx('seed-12', TxKind.expense, 480, 'Entertainment', 7, note: 'Movie night'),
    tx(
      'seed-13',
      TxKind.expense,
      120,
      'Food',
      8,
      note: 'Rice bowl',
      favorite: true,
    ),
    tx('seed-14', TxKind.expense, 65, 'Coffee', 8, note: 'Latte'),
    tx('seed-15', TxKind.expense, 1800, 'Shopping', 9, note: 'New sneakers'),
    tx('seed-16', TxKind.expense, 260, 'Food', 11, note: 'Dinner out'),
    tx('seed-17', TxKind.expense, 60, 'Coffee', 12, note: 'Americano'),
    tx(
      'seed-18',
      TxKind.expense,
      2000,
      'Savings',
      12,
      note: 'Monthly set-aside',
    ),
    tx('seed-19', TxKind.expense, 450, 'Bills', 15, note: 'Internet top-up'),
    tx('seed-20', TxKind.expense, 310, 'Pet Expenses', 18, note: 'Dog food'),
  ];
}

final List<TransactionModel> SEED_TRANSACTIONS = createSeedTransactions();
