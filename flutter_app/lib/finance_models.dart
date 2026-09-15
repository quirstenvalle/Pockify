import 'data/countries.dart';

enum TxKind { income, expense }

class TransactionModel {
  final String id;
  final TxKind kind;
  final double amount;
  final String category;
  final String? note;
  final String date;
  final String? method;
  final bool favorite;

  TransactionModel({
    required this.id,
    required this.kind,
    required this.amount,
    required this.category,
    this.note,
    required this.date,
    this.method,
    this.favorite = false,
  });

  TransactionModel copyWith({
    TxKind? kind,
    double? amount,
    String? category,
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
    'note': note,
    'date': date,
    'method': method,
    'favorite': favorite,
  };

  Map<String, dynamic> toSupabase() => {
    'id': id,
    'kind': kind.name,
    'amount': amount,
    'category': category,
    'note': note,
    'date': date,
    'method': method,
    'favorite': favorite,
  };

  factory TransactionModel.fromJson(Map<String, dynamic> json) =>
      TransactionModel(
        id: json['id'] as String,
        kind: TxKind.values.firstWhere(
          (kind) => kind.name == json['kind'],
          orElse: () => TxKind.expense,
        ),
        amount: (json['amount'] as num).toDouble(),
        category: json['category'] as String,
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
  final String category;
  final double limit;
  final String? _date;

  String get date => _date ?? todayIso();

  BudgetModel({
    required this.id,
    required this.category,
    required this.limit,
    this._date,
  });

  Map<String, dynamic> toSupabase() => {
    'id': id,
    'category': category,
    'limit_amount': limit,
    'budget_date': date,
  };

  factory BudgetModel.fromSupabase(Map<String, dynamic> json) {
    final rawDate = json['budget_date'] ?? json['created_at'];
    return BudgetModel(
      id: json['id'] as String,
      category: json['category'] as String,
      limit: (json['limit_amount'] as num).toDouble(),
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
    final used = spent[budget.category] ?? 0;
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
    final used = spent[budget.category] ?? 0;
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
  final spent = spentByCategory(txs);
  final alerts = <AlertModel>[];

  for (final budget in budgets) {
    final used = spent[budget.category] ?? 0;
    final pct = budget.limit == 0 ? 0.0 : used / budget.limit;

    if (pct >= 1) {
      alerts.add(
        AlertModel(
          id: 'budget-${budget.category}-over',
          level: 'over',
          title: 'You exceeded your ${budget.category} budget',
          body:
              '${peso(used)} of ${peso(budget.limit)} used — ${peso(used - budget.limit)} over the limit.',
        ),
      );
    } else if (pct >= 0.8) {
      alerts.add(
        AlertModel(
          id: 'budget-${budget.category}-warn',
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
  final totals = monthlyTotals(txs);
  final spent = spentByCategory(txs);
  var score = 50;

  if (totals.income > 0) {
    final ratio = totals.expenses / totals.income;
    if (ratio < 0.5) {
      score += 25;
    } else if (ratio < 0.7) {
      score += 18;
    } else if (ratio < 0.9) {
      score += 10;
    } else if (ratio < 1) {
      score += 4;
    } else {
      score -= 10;
    }
  }

  final over = budgets.where((b) => (spent[b.category] ?? 0) > b.limit).length;
  score += (15 - over * 8).clamp(-15, 15);

  final saved = spent['Savings'] ?? 0;
  if (saved > 0) {
    score += (saved / (totals.income == 0 ? 1 : totals.income) * 100)
        .round()
        .clamp(0, 10);
  }

  final monthExp = txs
      .where((x) => x.kind == TxKind.expense && isThisMonth(x.date))
      .toList();
  final essential = sumTransactions(
    monthExp.where((x) => categoryOf(x.category).essential).toList(),
  );
  if (monthExp.isNotEmpty) {
    score += ((essential / sumTransactions(monthExp) * 12)).round();
  }

  return score.clamp(0, 100);
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
