import 'package:flutter/material.dart';
import 'finance_models.dart';

class FinanceApp extends StatelessWidget {
  const FinanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pockify',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F766E)),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      ),
      home: const FinanceHomeScreen(),
    );
  }
}

class FinanceHomeScreen extends StatefulWidget {
  const FinanceHomeScreen({super.key});

  @override
  State<FinanceHomeScreen> createState() => _FinanceHomeScreenState();
}

class _FinanceHomeScreenState extends State<FinanceHomeScreen> {
  int _selectedIndex = 0;
  String _transactionQuery = '';
  String _transactionFilter = 'This Month';
  String _budgetCategory = 'Food';
  final TextEditingController _budgetCategoryController =
      TextEditingController(text: 'Food');
  final TextEditingController _budgetLimitController = TextEditingController();
  final List<TransactionModel> _transactions = [...SEED_TRANSACTIONS];
  final List<BudgetModel> _budgets = [...SEED_BUDGETS];

  @override
  void dispose() {
    _budgetCategoryController.dispose();
    _budgetLimitController.dispose();
    super.dispose();
  }

  String _pageTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Transactions';
      case 2:
        return 'Budgets';
      case 3:
        return 'Analytics';
      case 4:
        return 'Profile';
      default:
        return 'Pockify';
    }
  }

  void _addTransaction(TransactionModel tx) {
    setState(() {
      _transactions.insert(0, tx);
    });
  }

  void _toggleFavorite(String id) {
    setState(() {
      for (var i = 0; i < _transactions.length; i++) {
        final tx = _transactions[i];
        if (tx.id == id) {
          _transactions[i] = TransactionModel(
            id: tx.id,
            kind: tx.kind,
            amount: tx.amount,
            category: tx.category,
            note: tx.note,
            date: tx.date,
            method: tx.method,
            favorite: !tx.favorite,
          );
          break;
        }
      }
    });
  }

  void _removeTransaction(String id) {
    setState(() {
      _transactions.removeWhere((tx) => tx.id == id);
    });
  }

  void _addBudget() {
    final limit = double.tryParse(_budgetLimitController.text.trim());
    if (_budgetCategory.trim().isEmpty || limit == null || limit <= 0) {
      _showMessage('Add a category and a valid limit.');
      return;
    }

    setState(() {
      _budgets.add(
        BudgetModel(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          category: _budgetCategory.trim(),
          limit: limit,
        ),
      );
      _budgetLimitController.clear();
    });
    _showMessage('${_budgetCategory.trim()} budget set to ${peso(limit)}');
  }

  void _removeBudget(String id) {
    setState(() {
      _budgets.removeWhere((budget) => budget.id == id);
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _showAddTransactionSheet() {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    TxKind kind = TxKind.expense;
    String category = 'Food';
    final categories = CATEGORIES.map((c) => c.name).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add transaction',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      prefixText: '₱ ',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<TxKind>(
                    value: kind,
                    items: const [
                      DropdownMenuItem(
                        value: TxKind.expense,
                        child: Text('Expense'),
                      ),
                      DropdownMenuItem(
                        value: TxKind.income,
                        child: Text('Income'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setSheetState(() => kind = value);
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: 'Type',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: category,
                    items: categories
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setSheetState(() => category = value);
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteController,
                    decoration: const InputDecoration(
                      labelText: 'Note',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        final parsed = double.tryParse(
                          amountController.text.trim(),
                        );
                        if (parsed == null || parsed <= 0) return;

                        _addTransaction(
                          TransactionModel(
                            id: DateTime.now().millisecondsSinceEpoch
                                .toString(),
                            kind: kind,
                            amount: parsed,
                            category: category,
                            note: noteController.text.trim().isEmpty
                                ? null
                                : noteController.text.trim(),
                            date: todayIso(),
                            method: 'Cash',
                          ),
                        );
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Save transaction'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _dashboardView() {
    final totals = monthlyTotals(_transactions);
    final score = healthScore(_transactions, _budgets);
    final alerts = budgetAlerts(_transactions, _budgets);
    final recent = [..._transactions]..sort((a, b) => b.date.compareTo(a.date));
    final spent = spentByCategory(_transactions);
    final budgetTotal = _budgets.fold<double>(
      0,
      (sum, item) => sum + item.limit,
    );
    final budgetUsed = _budgets.fold<double>(
      0,
      (sum, item) => sum + (spent[item.category] ?? 0).clamp(0, item.limit),
    );
    final tips = smartSuggestions(_transactions);
    final tip = TIPS[DateTime.now().day % TIPS.length];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 0,
          color: const Color(0xFFECFDF5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Current balance',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      peso(totals.balance),
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.arrow_upward_rounded,
                            size: 14,
                            color: Colors.green,
                          ),
                          SizedBox(width: 4),
                          Text(
                            '22%',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 54,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.green.withValues(alpha: 0.25),
                          Colors.green.withValues(alpha: 0.02),
                        ],
                      ),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Row(
                        children: [
                          Expanded(child: SizedBox()),
                          Icon(Icons.trending_up_rounded, color: Colors.green),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _MiniStat(
                        label: 'Income',
                        value: peso(totals.income),
                        tone: Colors.green,
                      ),
                    ),
                    Expanded(
                      child: _MiniStat(
                        label: 'Expenses',
                        value: peso(totals.expenses),
                        tone: Colors.red,
                      ),
                    ),
                    Expanded(
                      child: _MiniStat(
                        label: 'Budget left',
                        value: peso(
                          (budgetTotal - budgetUsed).clamp(0, budgetTotal),
                        ),
                        tone: Colors.amber,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Card(
                elevation: 0,
                color: const Color(0xFFF8FAFC),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Wallet Health',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '$score',
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.only(bottom: 4),
                            child: Text(
                              '/100',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      LinearProgressIndicator(
                        value: score / 100,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(999),
                        color: score >= 75
                            ? Colors.green
                            : score >= 60
                            ? Colors.orange
                            : Colors.red,
                        backgroundColor: Colors.grey.shade200,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        score >= 75
                            ? 'Healthy'
                            : score >= 60
                            ? 'Fair'
                            : 'Needs Improvement',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Card(
                elevation: 0,
                color: const Color(0xFFF8FAFC),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Essential Streak',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(
                            Icons.local_fire_department_rounded,
                            color: Colors.orange,
                            size: 30,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${essentialStreak(_transactions)}',
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        essentialStreak(_transactions) > 0
                            ? 'Only essentials logged — keep it going.'
                            : 'Log only essentials today to start a streak.',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ...alerts
            .take(2)
            .map(
              (alert) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: alert.level == 'over'
                      ? Colors.red.shade50
                      : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: alert.level == 'over'
                        ? Colors.red.shade200
                        : Colors.orange.shade200,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      alert.level == 'over'
                          ? Icons.warning_amber_rounded
                          : Icons.info_outline_rounded,
                      color: alert.level == 'over' ? Colors.red : Colors.orange,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            alert.title,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            alert.body,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        const SizedBox(height: 10),
        Card(
          elevation: 0,
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Smart recommendations',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                ...tips.map(
                  (suggestion) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        suggestion,
                        style: const TextStyle(fontSize: 11, height: 1.4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Budget progress',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        ..._budgets.take(3).map((budget) {
          final used = spent[budget.category] ?? 0;
          final pct = ((used / budget.limit) * 100).clamp(0, 100);
          final cat = categoryOf(budget.category);
          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${cat.icon} ${budget.category}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${peso(used)} / ${peso(budget.limit)}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: pct / 100,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(999),
                    color: _colorFromHex(cat.color),
                    backgroundColor: Colors.grey.shade200,
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 16),
        const Text(
          'Recent transactions',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        Card(
          elevation: 0,
          child: Column(
            children: recent
                .take(5)
                .map(
                  (tx) => Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.grey.shade100,
                          ),
                          child: Center(
                            child: Text(
                              categoryOf(tx.category).icon,
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tx.category,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                tx.note ?? tx.date,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${tx.kind == TxKind.expense ? '-' : '+'}${peso(tx.amount)}',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: tx.kind == TxKind.expense
                                    ? Colors.red
                                    : Colors.green,
                              ),
                            ),
                            Text(
                              tx.date.substring(5),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          color: const Color(0xFFFFF7ED),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.lightbulb_outline_rounded,
                  color: Colors.orange,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tip of the day',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tip,
                        style: const TextStyle(fontSize: 11, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _transactionsView() {
    final sorted = _transactions.where((tx) {
      final query = _transactionQuery.trim().toLowerCase();
      final matchesQuery = query.isEmpty ||
          '${tx.category} ${tx.note ?? ''}'.toLowerCase().contains(query);
      final age = DateTime.now().difference(DateTime.parse(tx.date)).inDays;
      final matchesFilter = switch (_transactionFilter) {
        'Today' => age == 0,
        'This Week' => age <= 7,
        'This Month' => age <= 31,
        _ => true,
      };
      return matchesQuery && matchesFilter;
    }).toList()..sort((a, b) => b.date.compareTo(a.date));
    final spent = sorted
        .where((tx) => tx.kind == TxKind.expense)
        .fold<double>(0, (sum, tx) => sum + tx.amount);
    final earned = sorted
        .where((tx) => tx.kind == TxKind.income)
        .fold<double>(0, (sum, tx) => sum + tx.amount);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Money in',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        peso(earned),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Money out',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        peso(spent),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          onChanged: (value) => setState(() => _transactionQuery = value),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            hintText: 'Search expenses…',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final filter in const ['Today', 'This Week', 'This Month', 'All'])
                _FilterChip(
                  label: filter,
                  selected: _transactionFilter == filter,
                  onTap: () => setState(() => _transactionFilter = filter),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...sorted.map(
          (tx) => Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    categoryOf(tx.category).icon,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
              title: Text(
                tx.category,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                '${tx.note ?? tx.method ?? 'Entry'} • ${tx.date}',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${tx.kind == TxKind.expense ? '-' : '+'}${peso(tx.amount)}',
                    style: TextStyle(
                      color: tx.kind == TxKind.expense
                          ? Colors.red
                          : Colors.green,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () => _toggleFavorite(tx.id),
                        child: Icon(
                        Icons.star_rounded,
                        size: 14,
                        color: tx.favorite ? Colors.orange : Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => _removeTransaction(tx.id),
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          size: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _budgetsView() {
    final spentMap = spentByCategory(_transactions);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _SectionHeader(title: 'Budgets & goals'),
        const SizedBox(height: 12),
        ..._budgets.map((budget) {
          final used = spentMap[budget.category] ?? 0;
          final pct = budget.limit == 0
              ? 0.0
              : (used / budget.limit).clamp(0.0, 1.2);
          final cat = categoryOf(budget.category);
          final over = used > budget.limit;
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.teal.shade50,
                        child: Text(cat.icon),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          budget.category,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _removeBudget(budget.id),
                        icon: const Icon(Icons.delete_outline_rounded, size: 18),
                        color: Colors.grey,
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Delete budget',
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: over
                              ? Colors.red.shade50
                              : Colors.green.shade50,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${((used / budget.limit) * 100).clamp(0, 100).round()}%',
                          style: TextStyle(
                            color: over ? Colors.red : Colors.green,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: pct > 1 ? 1 : pct,
                    minHeight: 9,
                    borderRadius: BorderRadius.circular(999),
                    color: over ? Colors.red : Colors.teal,
                    backgroundColor: Colors.grey.shade200,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${peso(used)} / ${peso(budget.limit)} • ${peso((budget.limit - used).clamp(0, budget.limit))} left',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add budget',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: CATEGORIES
                      .take(8)
                      .map(
                        (c) => ChoiceChip(
                          label: Text('${c.icon} ${c.name}'),
                          selected: _budgetCategory == c.name,
                          onSelected: (_) => setState(() {
                            _budgetCategory = c.name;
                            _budgetCategoryController.text = c.name;
                          }),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _budgetCategoryController,
                        onChanged: (value) =>
                            setState(() => _budgetCategory = value),
                        decoration: InputDecoration(
                          hintText: 'Category',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 110,
                      child: TextField(
                        controller: _budgetLimitController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Limit',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _addBudget,
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _analyticsView() {
    final totals = monthlyTotals(_transactions);
    final sorted = spentByCategory(_transactions).entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topCategory = sorted.isNotEmpty ? sorted.first.key : '—';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _SectionHeader(title: 'Insights'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Income',
                value: peso(totals.income),
                accent: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Expenses',
                value: peso(totals.expenses),
                accent: Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Top spending categories',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                ...sorted
                    .take(5)
                    .map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(entry.key),
                                Text(peso(entry.value)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            LinearProgressIndicator(
                              value: sorted.first.value == 0
                                  ? 0
                                  : entry.value / sorted.first.value,
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(999),
                              color: Colors.teal,
                            ),
                          ],
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Monthly report',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                _MetricRow(label: 'Total income', value: peso(totals.income)),
                const SizedBox(height: 8),
                _MetricRow(
                  label: 'Total expenses',
                  value: peso(totals.expenses),
                ),
                const SizedBox(height: 8),
                _MetricRow(label: 'Net savings', value: peso(totals.balance)),
                const SizedBox(height: 8),
                _MetricRow(label: 'Top spending category', value: topCategory),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _profileView() {
    final score = healthScore(_transactions, _budgets);
    final favorites = _transactions.where((tx) => tx.favorite).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Wallet health',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                Text(
                  '$score / 100',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Essential spending streak: ${essentialStreak(_transactions)} days',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: score / 100,
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(999),
                  color: score >= 75
                      ? Colors.green
                      : score >= 60
                      ? Colors.orange
                      : Colors.red,
                  backgroundColor: Colors.grey.shade200,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const _SectionHeader(title: 'Favorite transactions'),
        const SizedBox(height: 12),
        if (favorites.isEmpty)
          const Text('No favorites yet.')
        else
          ...favorites.map(
            (tx) => ListTile(
              leading: const Icon(Icons.star, color: Colors.amber),
              title: Text(tx.category),
              subtitle: Text(tx.note ?? 'Favorite item'),
              trailing: Text(
                '${tx.kind == TxKind.expense ? '-' : '+'}${peso(tx.amount)}',
              ),
            ),
          ),
      ],
    );
  }

  Widget _navItem({
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required int index,
  }) {
    final selected = _selectedIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedIndex = index),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? selectedIcon : icon,
                size: 21,
                color: selected ? const Color(0xFF0F766E) : Colors.grey,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.black87 : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _dashboardView(),
      _transactionsView(),
      _budgetsView(),
      _analyticsView(),
      _profileView(),
    ];

    final alertCount = budgetAlerts(_transactions, _budgets).length;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(78),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xFFCCFBF1),
                  child: Text(
                    'A',
                    style: const TextStyle(
                      color: Color(0xFF0F766E),
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Hi, Alex',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        _pageTitle(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (_selectedIndex == 0)
                        Text(
                          MaterialLocalizations.of(context).formatMediumDate(DateTime.now()),
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                    ],
                  ),
                ),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      onPressed: () => setState(() => _selectedIndex = 4),
                      icon: const Icon(Icons.notifications_none_rounded),
                      tooltip: 'Notifications',
                    ),
                    if (alertCount > 0)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          width: 17,
                          height: 17,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: Color(0xFF0F766E),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '$alertCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 10),
        child: Material(
          elevation: 8,
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            child: Row(
              children: [
                _navItem(
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home,
                  label: 'Home',
                  index: 0,
                ),
                _navItem(
                  icon: Icons.receipt_long_outlined,
                  selectedIcon: Icons.receipt_long,
                  label: 'Activity',
                  index: 1,
                ),
                Expanded(
                  child: Transform.translate(
                    offset: const Offset(0, -18),
                    child: FloatingActionButton(
                      onPressed: _showAddTransactionSheet,
                      tooltip: 'Quick add',
                      elevation: 5,
                      backgroundColor: const Color(0xFF0F766E),
                      foregroundColor: Colors.white,
                      child: const Icon(Icons.add, size: 26),
                    ),
                  ),
                ),
                _navItem(
                  icon: Icons.account_balance_wallet_outlined,
                  selectedIcon: Icons.account_balance_wallet,
                  label: 'Budgets',
                  index: 2,
                ),
                _navItem(
                  icon: Icons.insights_outlined,
                  selectedIcon: Icons.insights,
                  label: 'Insights',
                  index: 3,
                ),
                _navItem(
                  icon: Icons.person_outline,
                  selectedIcon: Icons.person,
                  label: 'Profile',
                  index: 4,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color tone;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: tone,
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    this.selected = false,
    this.onTap = _noop,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF0F766E) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }
}

void _noop() {}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _StatCard({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: accent, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;

  const _MetricRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(color: Colors.grey)),
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

Color _colorFromHex(String hexString) {
  final cleaned = hexString.replaceFirst('#', '');
  final value = cleaned.length == 6 ? cleaned : 'FF$cleaned';
  return Color(int.parse(value, radix: 16) + 0xFF000000);
}
