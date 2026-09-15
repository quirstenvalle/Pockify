import 'package:flutter/material.dart';

import '../api/api_config.dart';
import '../api/finance_repository.dart';
import '../api/profile_repository.dart';
import '../auth/auth_models.dart';
import '../data/countries.dart';
import '../finance_models.dart';
import '../widgets/country_picker.dart';

const List<String> kIncomeSources = [
  'Allowance',
  'Salary',
  'Freelance / Side Income',
  'Business',
  'Other',
];

const List<String> kIncomeFrequencies = [
  'Weekly',
  'Every two weeks',
  'Monthly',
  'Irregularly',
];

const List<String> kSavingsFrequencies = ['Weekly', 'Every two weeks', 'Monthly'];

const List<String> kBudgetObjectives = [
  'Save more money',
  'Control my spending',
  'Build an emergency fund',
  'Keep track of my expenses',
  'Pay off debt',
  'Reach a specific financial goal',
];

/// First-login financial profile setup, shown once right after a new
/// account is verified. Answers personalize the Budgets tab (a savings
/// goal is created automatically from the final step).
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.user,
    required this.onComplete,
  });

  final AuthUser user;
  final VoidCallback onComplete;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _accent = Color(0xFFFF7F20);

  final _pageController = PageController();
  final _incomeAmountController = TextEditingController();
  final _goalAmountController = TextEditingController();
  final _profiles = ProfileRepository();

  late final bool _needsCountry = widget.user.country == null;
  String? _country;
  String? _incomeSource;
  String? _incomeFrequency;
  final Set<String> _budgetObjectives = {};
  bool _isRecurringGoal = false;
  String _goalFrequency = kSavingsFrequencies.last;

  int _index = 0;
  bool _busy = false;
  String? _error;

  int get _totalSteps => _needsCountry ? 6 : 5;

  /// Maps a page index to a logical step: 0=country 1=source 2=frequency
  /// 3=amount 4=objectives 5=goal. When the country step isn't needed,
  /// indices shift up by one.
  int _logical(int index) => _needsCountry ? index : index + 1;

  @override
  void dispose() {
    _pageController.dispose();
    _incomeAmountController.dispose();
    _goalAmountController.dispose();
    super.dispose();
  }

  String get _currencyValue {
    if (widget.user.currency != null) return widget.user.currency!;
    if (_country != null) return currencyCodeForCountry(_country!);
    return 'USD';
  }

  String get _currencySymbol => currencySymbolForCurrency(_currencyValue);

  Future<void> _pickCountry() async {
    final selected = await showCountryPicker(context, initial: _country);
    if (selected == null || !mounted) return;
    setState(() => _country = selected);
  }

  String? _validateCurrentStep() {
    switch (_logical(_index)) {
      case 0:
        return _country == null ? 'Select your country/region.' : null;
      case 1:
        return _incomeSource == null ? 'Select your main source of income.' : null;
      case 2:
        return _incomeFrequency == null ? 'Select how often you receive money.' : null;
      case 3:
        final value = double.tryParse(_incomeAmountController.text.trim());
        return (value == null || value <= 0)
            ? 'Enter an amount greater than 0.'
            : null;
      case 4:
        return _budgetObjectives.isEmpty
            ? 'Select at least one goal for your budget.'
            : null;
      case 5:
        final value = double.tryParse(_goalAmountController.text.trim());
        return (value == null || value <= 0)
            ? 'Enter an amount greater than 0.'
            : null;
      default:
        return null;
    }
  }

  Future<void> _next() async {
    final error = _validateCurrentStep();
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    setState(() => _error = null);

    if (_index == _totalSteps - 1) {
      await _finish();
      return;
    }

    setState(() => _index += 1);
    _pageController.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _back() {
    if (_index == 0) return;
    setState(() {
      _index -= 1;
      _error = null;
    });
    _pageController.previousPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _finish() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      var user = widget.user;

      if (_needsCountry && _country != null) {
        user = await _profiles.updateProfile(
          user: user,
          name: user.name,
          currency: currencyCodeForCountry(_country!),
          country: _country,
          employmentStatus: user.employmentStatus,
          birthDate: user.birthDate,
          monthlyIncome: user.monthlyIncome,
          monthlyBudgetGoal: user.monthlyBudgetGoal,
          avatarUrl: user.avatarUrl,
        );
      }

      final incomeAmount = double.parse(_incomeAmountController.text.trim());
      final goalAmount = double.parse(_goalAmountController.text.trim());

      final goal = _isRecurringGoal
          ? GoalModel(
              id: DateTime.now().microsecondsSinceEpoch.toString(),
              title: 'Recurring Savings',
              target: 0,
              current: 0,
              isRecurring: true,
              recurringAmount: goalAmount,
              recurringFrequency: _goalFrequency,
            )
          : GoalModel(
              id: DateTime.now().microsecondsSinceEpoch.toString(),
              title: 'Savings Goal',
              target: goalAmount,
              current: 0,
            );

      user = await _profiles.completeOnboarding(
        user: user,
        incomeSource: _incomeSource!,
        incomeFrequency: _incomeFrequency!,
        incomeAmount: incomeAmount,
        budgetObjectives: _budgetObjectives.toList(),
      );

      if (ApiConfig.useSupabase) {
        try {
          await FinanceRepository().upsertGoal(goal);
        } catch (_) {
          // Non-fatal: the goal can be added manually from the Budgets tab.
        }
      }

      setActiveCurrency(user.currency);
      if (!mounted) return;
      widget.onComplete();
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = 'Could not save your setup. $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F1),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        'Step ${_index + 1} of $_totalSteps',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6D6962),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: (_index + 1) / _totalSteps,
                      minHeight: 6,
                      color: _accent,
                      backgroundColor: const Color(0xFFEAE5DC),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: Card(
                      color: Colors.white,
                      margin: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(22),
                        child: PageView(
                          controller: _pageController,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            for (var i = 0; i < _totalSteps; i++)
                              SingleChildScrollView(child: _buildStep(_logical(i))),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: const TextStyle(
                        color: Color(0xFFDC2626),
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      if (_index > 0)
                        TextButton(
                          onPressed: _busy ? null : _back,
                          child: const Text('Back'),
                        ),
                      const Spacer(),
                      FilledButton(
                        onPressed: _busy ? null : _next,
                        style: FilledButton.styleFrom(
                          backgroundColor: _accent,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: _busy
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _index == _totalSteps - 1 ? 'Finish' : 'Next',
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep(int step) {
    switch (step) {
      case 0:
        return _countryStep();
      case 1:
        return _singleSelectStep(
          title: 'What is your main source of income?',
          options: kIncomeSources,
          selected: _incomeSource,
          onSelected: (value) => setState(() => _incomeSource = value),
        );
      case 2:
        return _singleSelectStep(
          title: 'How often do you receive money?',
          options: kIncomeFrequencies,
          selected: _incomeFrequency,
          onSelected: (value) => setState(() => _incomeFrequency = value),
        );
      case 3:
        return _incomeAmountStep();
      case 4:
        return _budgetObjectivesStep();
      case 5:
        return _savingsGoalStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _stepTitle(String title) => Text(
    title,
    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
  );

  Widget _countryStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepTitle('What country are you in?'),
        const SizedBox(height: 6),
        const Text(
          'We use this to set your currency automatically.',
          style: TextStyle(fontSize: 12, color: Color(0xFF6D6962)),
        ),
        const SizedBox(height: 18),
        InkWell(
          onTap: _pickCountry,
          borderRadius: BorderRadius.circular(6),
          child: InputDecorator(
            decoration: InputDecoration(
              hintText: 'Select country',
              prefixIcon: const Icon(Icons.public, size: 18),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              suffixIcon: const Icon(Icons.expand_more, size: 18),
            ),
            child: Text(_country ?? 'Select country'),
          ),
        ),
      ],
    );
  }

  Widget _singleSelectStep({
    required String title,
    required List<String> options,
    required String? selected,
    required ValueChanged<String> onSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepTitle(title),
        const SizedBox(height: 16),
        for (final option in options)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _OptionTile(
              label: option,
              selected: option == selected,
              onTap: () => onSelected(option),
            ),
          ),
      ],
    );
  }

  Widget _incomeAmountStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepTitle('How much do you typically receive?'),
        const SizedBox(height: 16),
        TextField(
          controller: _incomeAmountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            prefixText: '$_currencySymbol ',
            hintText: '0.00',
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
          ),
        ),
      ],
    );
  }

  Widget _budgetObjectivesStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepTitle('What would you like to achieve with your budget?'),
        const SizedBox(height: 6),
        const Text(
          'Select all that apply.',
          style: TextStyle(fontSize: 12, color: Color(0xFF6D6962)),
        ),
        const SizedBox(height: 12),
        for (final objective in kBudgetObjectives)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _OptionTile(
              label: objective,
              selected: _budgetObjectives.contains(objective),
              checkbox: true,
              onTap: () => setState(() {
                if (!_budgetObjectives.remove(objective)) {
                  _budgetObjectives.add(objective);
                }
              }),
            ),
          ),
      ],
    );
  }

  Widget _savingsGoalStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepTitle('How much would you like to save?'),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _GoalTypeTile(
                label: 'Total Savings Goal',
                subtitle: 'e.g. ${_currencySymbol}10,000 total',
                selected: !_isRecurringGoal,
                onTap: () => setState(() => _isRecurringGoal = false),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _GoalTypeTile(
                label: 'Regular Savings Amount',
                subtitle: 'e.g. ${_currencySymbol}500 / month',
                selected: _isRecurringGoal,
                onTap: () => setState(() => _isRecurringGoal = true),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        TextField(
          controller: _goalAmountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: _isRecurringGoal ? 'Amount per period' : 'Target amount',
            prefixText: '$_currencySymbol ',
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
          ),
        ),
        if (_isRecurringGoal) ...[
          const SizedBox(height: 14),
          const Text(
            'How often?',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final freq in kSavingsFrequencies)
                ChoiceChip(
                  label: Text(freq),
                  selected: _goalFrequency == freq,
                  onSelected: (_) => setState(() => _goalFrequency = freq),
                  selectedColor: _accent.withValues(alpha: 0.15),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
    this.checkbox = false,
  });

  final String label;
  final bool selected;
  final bool checkbox;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected
                ? const Color(0xFFFF7F20)
                : const Color(0xFFD8D3CB),
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: selected ? const Color(0xFFFFF1E6) : Colors.white,
        ),
        child: Row(
          children: [
            Icon(
              checkbox
                  ? (selected ? Icons.check_box : Icons.check_box_outline_blank)
                  : (selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked),
              size: 18,
              color: selected ? const Color(0xFFFF7F20) : const Color(0xFF9A958C),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
          ],
        ),
      ),
    );
  }
}

class _GoalTypeTile extends StatelessWidget {
  const _GoalTypeTile({
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected
                ? const Color(0xFFFF7F20)
                : const Color(0xFFD8D3CB),
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: selected ? const Color(0xFFFFF1E6) : Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 10, color: Color(0xFF6D6962)),
            ),
          ],
        ),
      ),
    );
  }
}
