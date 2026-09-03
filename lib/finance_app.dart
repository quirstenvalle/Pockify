import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'api/api_config.dart';
import 'api/finance_repository.dart';
import 'auth/auth_models.dart';
import 'auth/auth_service.dart';
import 'auth_validation.dart';
import 'finance_models.dart';
import 'form_validation.dart';
import 'responsive.dart';
import 'screens/email_verification_screen.dart';
import 'widgets/charts.dart';

TextTheme _zeroLetterSpacing(TextTheme textTheme) => textTheme.copyWith(
  displayLarge: textTheme.displayLarge?.copyWith(letterSpacing: 0),
  displayMedium: textTheme.displayMedium?.copyWith(letterSpacing: 0),
  displaySmall: textTheme.displaySmall?.copyWith(letterSpacing: 0),
  headlineLarge: textTheme.headlineLarge?.copyWith(letterSpacing: 0),
  headlineMedium: textTheme.headlineMedium?.copyWith(letterSpacing: 0),
  headlineSmall: textTheme.headlineSmall?.copyWith(letterSpacing: 0),
  titleLarge: textTheme.titleLarge?.copyWith(letterSpacing: 0),
  titleMedium: textTheme.titleMedium?.copyWith(letterSpacing: 0),
  titleSmall: textTheme.titleSmall?.copyWith(letterSpacing: 0),
  bodyLarge: textTheme.bodyLarge?.copyWith(letterSpacing: 0),
  bodyMedium: textTheme.bodyMedium?.copyWith(letterSpacing: 0),
  bodySmall: textTheme.bodySmall?.copyWith(letterSpacing: 0),
  labelLarge: textTheme.labelLarge?.copyWith(letterSpacing: 0),
  labelMedium: textTheme.labelMedium?.copyWith(letterSpacing: 0),
  labelSmall: textTheme.labelSmall?.copyWith(letterSpacing: 0),
);

class FinanceApp extends StatefulWidget {
  const FinanceApp({super.key});

  @override
  State<FinanceApp> createState() => _FinanceAppState();
}

class _FinanceAppState extends State<FinanceApp> {
  bool _booting = true;
  bool _authenticated = false;
  String? _pendingVerificationEmail;
  String? _pendingDemoCode;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final user = await AuthService.instance.restoreSession();
    if (!mounted) return;
    setState(() {
      _authenticated = user != null;
      _booting = false;
    });
  }

  Future<void> _handleLogout() async {
    await AuthService.instance.logout();
    if (!mounted) return;
    setState(() {
      _authenticated = false;
      _pendingVerificationEmail = null;
      _pendingDemoCode = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pockify',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFF39A42)),
        scaffoldBackgroundColor: const Color(0xFFF3F1EB),
        cardColor: const Color(0xFFFDFCFA),
        fontFamilyFallback: const ['NotoColorEmoji'],
        textTheme: _zeroLetterSpacing(Typography.material2021().black),
        cardTheme: CardThemeData(
          color: const Color(0xFFFDFCFA),
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF0EEE9),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: const BorderSide(color: Color(0xFFF39A42)),
          ),
        ),
      ),
      home: _booting
          ? const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: Color(0xFFFF7F20)),
              ),
            )
          : _authenticated
          ? FinanceHomeScreen(onLogout: _handleLogout)
          : _pendingVerificationEmail != null
          ? EmailVerificationScreen(
              email: _pendingVerificationEmail!,
              initialDemoCode: _pendingDemoCode,
              onVerified: () => setState(() {
                _authenticated = true;
                _pendingVerificationEmail = null;
                _pendingDemoCode = null;
              }),
              onBackToAuth: () => setState(() {
                _pendingVerificationEmail = null;
                _pendingDemoCode = null;
              }),
            )
          : AuthScreen(
              onAuthenticated: () => setState(() => _authenticated = true),
              onNeedsVerification: (email, demoCode) => setState(() {
                _pendingVerificationEmail = email;
                _pendingDemoCode = demoCode;
              }),
            ),
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    required this.onAuthenticated,
    required this.onNeedsVerification,
  });

  final VoidCallback onAuthenticated;
  final void Function(String email, String? demoCode) onNeedsVerification;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _loginMode = true;
  bool _busy = false;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _incomeController = TextEditingController();
  final _budgetGoalController = TextEditingController();
  String _currency = 'Select currency';
  String _employmentStatus = 'Select status';
  DateTime? _birthDate;
  final _auth = AuthService.instance;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _incomeController.dispose();
    _budgetGoalController.dispose();
    super.dispose();
  }

  String get _birthDateLabel {
    final date = _birthDate;
    if (date == null) return 'mm/dd/yyyy';
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    return '$mm/$dd/${date.year}';
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Select birth date',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: const Color(0xFFFF7F20),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null || !mounted) return;
    setState(() => _birthDate = picked);
  }

  Future<void> _submit() async {
    if (_busy) return;

    final result = _loginMode
        ? validateLogin(
            email: _emailController.text,
            password: _passwordController.text,
          )
        : validateSignup(
            name: _nameController.text,
            email: _emailController.text,
            password: _passwordController.text,
            confirmPassword: _confirmController.text,
            currency: _currency,
            employmentStatus: _employmentStatus,
            birthDate: _birthDate,
          );

    if (!result.ok) {
      await _showErrorDialog(
        result.message ?? 'Enter valid account details.',
      );
      return;
    }

    setState(() => _busy = true);
    try {
      double? parseMoney(String raw) {
        final cleaned = raw.trim().replaceAll(RegExp(r'[^0-9.]'), '');
        if (cleaned.isEmpty) return null;
        return double.tryParse(cleaned);
      }

      final authResult = _loginMode
          ? await _auth.login(
              email: _emailController.text,
              password: _passwordController.text,
            )
          : await _auth.register(
              name: _nameController.text,
              email: _emailController.text,
              password: _passwordController.text,
              currency: _currency,
              employmentStatus: _employmentStatus,
              birthDate: _birthDate,
              monthlyIncome: parseMoney(_incomeController.text),
              monthlyBudgetGoal: parseMoney(_budgetGoalController.text),
            );

      if (!mounted) return;

      if (!_loginMode) {
        if (authResult.requiresVerification) {
          widget.onNeedsVerification(
            _emailController.text.trim().toLowerCase(),
            authResult.demoCode,
          );
          return;
        }

        if (authResult.ok && authResult.user != null) {
          // Should not happen with email confirmation enabled.
          widget.onNeedsVerification(
            _emailController.text.trim().toLowerCase(),
            authResult.demoCode,
          );
          return;
        }

        await _showErrorDialog(
          authResult.message ?? 'Sign up failed. Please try again.',
        );
        return;
      }

      if (authResult.ok && authResult.user != null) {
        widget.onAuthenticated();
        return;
      }

      if (authResult.requiresVerification) {
        widget.onNeedsVerification(
          _emailController.text.trim().toLowerCase(),
          authResult.demoCode,
        );
        return;
      }

      await _showErrorDialog(
        authResult.message ?? 'Sign in failed. Please try again.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showErrorDialog(String message) {
    return _showFloatingModal(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 48),
          const SizedBox(height: 14),
          const Text(
            'Invalid input',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6D6962),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF7F20),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('OK'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showFloatingModal({
    required Widget child,
    bool barrierDismissible = true,
  }) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, animation, secondaryAnimation) {
        return SafeArea(
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 340),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 28,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: child,
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: curved, child: child),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            Responsive.pagePadding(context).left,
            12,
            Responsive.pagePadding(context).right,
            24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 22),
                child: Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet,
                      color: Color(0xFFFF7F20),
                      size: 18,
                    ),
                    SizedBox(width: 5),
                    Text(
                      'Pockify',
                      style: TextStyle(
                        color: Color(0xFFFF7F20),
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: Responsive.authMaxWidth(context),
                  ),
                  child: Card(
                    color: Colors.white,
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            _loginMode ? 'Welcome back' : 'Create Account',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _loginMode
                                ? 'Sign in to securely manage your finances.'
                                : 'Start managing your finances today.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF6D6962),
                            ),
                          ),
                          const SizedBox(height: 26),
                          if (!_loginMode) ...[
                            const Text(
                              'Full Name',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 5),
                            TextField(
                              controller: _nameController,
                              decoration: _authInput(
                                Icons.person_outline,
                                'Mark Santos',
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],
                          if (!_loginMode) ...[
                            const Text(
                              'Monthly Income',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 5),
                            TextField(
                              controller: _incomeController,
                              keyboardType: TextInputType.number,
                              decoration: _authInput(null, 'e.g. 5000'),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Preferred Currency',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 5),
                            DropdownButtonFormField<String>(
                              initialValue: _currency,
                              items:
                                  const [
                                        'Select currency',
                                        'PHP (₱)',
                                        'USD (\$)',
                                        'EUR (€)',
                                      ]
                                      .map(
                                        (item) => DropdownMenuItem(
                                          value: item,
                                          child: Text(item),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (value) => setState(
                                () => _currency = value ?? _currency,
                              ),
                              decoration: _authInput(null, 'Select currency'),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Birth Date',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 5),
                            InkWell(
                              onTap: _pickBirthDate,
                              borderRadius: BorderRadius.circular(999),
                              child: InputDecorator(
                                decoration: _authInput(null, 'mm/dd/yyyy')
                                    .copyWith(
                                      suffixIcon: const Icon(
                                        Icons.calendar_today_outlined,
                                        size: 15,
                                      ),
                                    ),
                                child: Text(
                                  _birthDateLabel,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: _birthDate == null
                                        ? const Color(0xFF9A958C)
                                        : const Color(0xFF1F1F1F),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Monthly Budget Goal',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 5),
                            TextField(
                              controller: _budgetGoalController,
                              keyboardType: TextInputType.number,
                              decoration: _authInput(null, '\$ 0.00'),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Employment Status',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 5),
                            DropdownButtonFormField<String>(
                              initialValue: _employmentStatus,
                              items:
                                  const [
                                        'Select status',
                                        'Employed',
                                        'Self-employed',
                                        'Student',
                                        'Unemployed',
                                      ]
                                      .map(
                                        (item) => DropdownMenuItem(
                                          value: item,
                                          child: Text(item),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (value) => setState(
                                () => _employmentStatus =
                                    value ?? _employmentStatus,
                              ),
                              decoration: _authInput(null, 'Select status'),
                            ),
                            const SizedBox(height: 14),
                          ],
                          const Text(
                            'Email Address',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 5),
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: _authInput(
                              Icons.mail_outline,
                              'name@example.com',
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Password',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 5),
                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: _authInput(
                              Icons.lock_outline,
                              '••••••••',
                            ),
                          ),
                          if (!_loginMode) ...[
                            const SizedBox(height: 6),
                            const Text(
                              'Use 8+ characters, start with a capital letter, and include a special character.',
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFF6D6962),
                              ),
                            ),
                          ],
                          if (!_loginMode) ...[
                            const SizedBox(height: 14),
                            TextField(
                              controller: _confirmController,
                              obscureText: true,
                              decoration: _authInput(
                                Icons.lock_outline,
                                'Confirm password',
                              ),
                            ),
                          ],
                          if (_loginMode)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => _showMessage(
                                  'Password reset is not connected yet.',
                                ),
                                child: const Text(
                                  'Forgot Password?',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFFFF7F20),
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 8),
                          FilledButton(
                            onPressed: _busy ? null : _submit,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFFF7F20),
                              padding: const EdgeInsets.symmetric(vertical: 14),
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
                                : Text(_loginMode ? 'Sign In' : 'Sign Up'),
                          ),
                          const SizedBox(height: 22),
                          Row(
                            children: [
                              const Expanded(child: Divider()),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                child: Text(
                                  _loginMode
                                      ? 'or continue with'
                                      : 'or sign up with',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                              const Expanded(child: Divider()),
                            ],
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: () => _showMessage(
                              'Google sign-in is not connected yet.',
                            ),
                            icon: const Icon(Icons.login, size: 16),
                            label: const Text(
                              'Continue with Google',
                              style: TextStyle(fontSize: 11),
                            ),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: () => _showMessage(
                              'Apple sign-in is not connected yet.',
                            ),
                            icon: const Icon(Icons.phone_iphone, size: 16),
                            label: const Text(
                              'Continue with Apple',
                              style: TextStyle(fontSize: 11),
                            ),
                          ),
                          const SizedBox(height: 22),
                          TextButton(
                            onPressed: () =>
                                setState(() => _loginMode = !_loginMode),
                            child: Text(
                              _loginMode
                                  ? "Don't have an account? Sign Up"
                                  : 'Already have an account? Sign In',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFFFF7F20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _authInput(IconData? icon, String hint) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 17),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Color(0xFFD8D3CB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Color(0xFFD8D3CB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Color(0xFFFF7F20)),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class FinanceHomeScreen extends StatefulWidget {
  const FinanceHomeScreen({super.key, required this.onLogout});

  final Future<void> Function() onLogout;

  @override
  State<FinanceHomeScreen> createState() => _FinanceHomeScreenState();
}

class _FinanceHomeScreenState extends State<FinanceHomeScreen> {
  int _selectedIndex = 0;
  String _transactionQuery = '';
  String _transactionFilter = 'This Month';
  String _budgetCategory = 'Food';
  AuthUser? _user;
  bool _loggingOut = false;
  bool _loadingFinance = true;
  final FinanceRepository _finance = FinanceRepository();
  final TextEditingController _budgetCategoryController = TextEditingController(
    text: 'Food',
  );
  final TextEditingController _budgetLimitController = TextEditingController();
  final TextEditingController _goalTitleController = TextEditingController();
  final TextEditingController _goalTargetController = TextEditingController();
  final List<TransactionModel> _transactions = [];
  final List<BudgetModel> _budgets = [];
  final List<GoalModel> _goals = [];
  final Set<String> _readAlertIds = {};
  final Map<String, bool> _settings = {
    'Daily expense reminder': true,
    'Budget threshold alerts': true,
    'Streak celebrations': true,
    'Biometric lock': false,
  };

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadFinanceData();
  }

  Future<void> _loadUser() async {
    final user = await AuthService.instance.currentUser();
    if (!mounted) return;
    setState(() => _user = user);
  }

  Future<void> _loadFinanceData() async {
    if (!ApiConfig.useSupabase) {
      setState(() {
        _transactions
          ..clear()
          ..addAll(SEED_TRANSACTIONS);
        _budgets
          ..clear()
          ..addAll(SEED_BUDGETS);
        _goals
          ..clear()
          ..addAll(SEED_GOALS);
        _loadingFinance = false;
      });
      return;
    }

    try {
      final results = await Future.wait([
        _finance.loadTransactions(),
        _finance.loadBudgets(),
        _finance.loadGoals(),
      ]);
      if (!mounted) return;
      setState(() {
        _transactions
          ..clear()
          ..addAll(results[0] as List<TransactionModel>);
        _budgets
          ..clear()
          ..addAll(results[1] as List<BudgetModel>);
        _goals
          ..clear()
          ..addAll(results[2] as List<GoalModel>);
        _loadingFinance = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loadingFinance = false);
      _showMessage('Could not load finance data. $error');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String get _displayName {
    final name = _user?.name.trim();
    if (name == null || name.isEmpty) return 'Pockify user';
    return name;
  }

  String get _greetingName {
    final parts = _displayName.split(RegExp(r'\s+'));
    return parts.isEmpty ? 'there' : parts.first;
  }

  String get _initial {
    final name = _displayName.trim();
    if (name.isEmpty) return 'P';
    return name.substring(0, 1).toUpperCase();
  }

  Future<void> _confirmLogout() async {
    if (_loggingOut) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'You will need to sign in again to access your account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF7F20),
            ),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _loggingOut = true);
    try {
      await widget.onLogout();
    } finally {
      if (mounted) setState(() => _loggingOut = false);
    }
  }

  @override
  void dispose() {
    _budgetCategoryController.dispose();
    _budgetLimitController.dispose();
    _goalTitleController.dispose();
    _goalTargetController.dispose();
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

  Future<void> _addTransaction(TransactionModel tx) async {
    setState(() => _transactions.insert(0, tx));
    if (!ApiConfig.useSupabase) return;
    try {
      await _finance.upsertTransaction(tx);
    } catch (error) {
      if (!mounted) return;
      setState(() => _transactions.removeWhere((item) => item.id == tx.id));
      _showMessage('Could not save transaction. $error');
    }
  }

  Future<void> _toggleFavorite(String id) async {
    final index = _transactions.indexWhere((tx) => tx.id == id);
    if (index == -1) return;
    final previous = _transactions[index];
    final updated = previous.copyWith(favorite: !previous.favorite);
    setState(() => _transactions[index] = updated);
    if (!ApiConfig.useSupabase) return;
    try {
      await _finance.upsertTransaction(updated);
    } catch (error) {
      if (!mounted) return;
      setState(() => _transactions[index] = previous);
      _showMessage('Could not update favorite. $error');
    }
  }

  Future<void> _removeTransaction(String id) async {
    final index = _transactions.indexWhere((tx) => tx.id == id);
    if (index == -1) return;
    final removed = _transactions[index];
    setState(() => _transactions.removeAt(index));
    if (!ApiConfig.useSupabase) return;
    try {
      await _finance.deleteTransaction(id);
    } catch (error) {
      if (!mounted) return;
      setState(() => _transactions.insert(index, removed));
      _showMessage('Could not delete transaction. $error');
    }
  }

  Future<void> _confirmRemoveTransaction(String id) async {
    final confirmed = await _confirmAction('Delete transaction?');
    if (confirmed) await _removeTransaction(id);
  }

  Future<void> _addBudget() async {
    final result = validateBudgetInput(
      category: _budgetCategory,
      limitText: _budgetLimitController.text,
    );
    if (!result.ok) {
      _showMessage(result.message ?? 'Add a category and a valid limit.');
      return;
    }

    final budget = buildBudget(
      category: _budgetCategory,
      limitText: _budgetLimitController.text,
    );
    setState(() {
      _budgets.add(budget);
      _budgetLimitController.clear();
    });
    _showMessage('${budget.category} budget set to ${peso(budget.limit)}');
    if (!ApiConfig.useSupabase) return;
    try {
      await _finance.upsertBudget(budget);
    } catch (error) {
      if (!mounted) return;
      setState(() => _budgets.removeWhere((item) => item.id == budget.id));
      _showMessage('Could not save budget. $error');
    }
  }

  Future<void> _removeBudget(String id) async {
    final index = _budgets.indexWhere((budget) => budget.id == id);
    if (index == -1) return;
    final removed = _budgets[index];
    setState(() => _budgets.removeAt(index));
    if (!ApiConfig.useSupabase) return;
    try {
      await _finance.deleteBudget(id);
    } catch (error) {
      if (!mounted) return;
      setState(() => _budgets.insert(index, removed));
      _showMessage('Could not delete budget. $error');
    }
  }

  Future<void> _confirmRemoveBudget(String id) async {
    final confirmed = await _confirmAction('Delete budget?');
    if (confirmed) await _removeBudget(id);
  }

  Future<bool> _confirmAction(String title) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(title),
            content: const Text('This action cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _addGoal() async {
    final result = validateGoalInput(
      title: _goalTitleController.text,
      targetText: _goalTargetController.text,
    );
    if (!result.ok) {
      _showMessage(result.message ?? 'Add a goal name and a valid target.');
      return;
    }

    final goal = buildGoal(
      title: _goalTitleController.text,
      targetText: _goalTargetController.text,
    );
    setState(() {
      _goals.add(goal);
      _goalTitleController.clear();
      _goalTargetController.clear();
    });
    _showMessage('${goal.title} goal added.');
    if (!ApiConfig.useSupabase) return;
    try {
      await _finance.upsertGoal(goal);
    } catch (error) {
      if (!mounted) return;
      setState(() => _goals.removeWhere((item) => item.id == goal.id));
      _showMessage('Could not save goal. $error');
    }
  }

  Future<void> _contributeGoal(String id) async {
    final index = _goals.indexWhere((goal) => goal.id == id);
    if (index == -1) return;
    final previous = _goals[index];
    final updated = contributeToGoal(previous);
    setState(() => _goals[index] = updated);
    if (!ApiConfig.useSupabase) return;
    try {
      await _finance.upsertGoal(updated);
    } catch (error) {
      if (!mounted) return;
      setState(() => _goals[index] = previous);
      _showMessage('Could not update goal. $error');
    }
  }

  void _markAlertRead(String id) {
    setState(() => _readAlertIds.add(id));
  }

  void _markAllAlertsRead(List<AlertModel> alerts) {
    setState(() => _readAlertIds.addAll(alerts.map((alert) => alert.id)));
  }

  void _showNotifications(BuildContext buttonContext) {
    final alerts = budgetAlerts(_transactions, _budgets);
    final box = buttonContext.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;

    final overlayBox =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final offset = box.localToGlobal(Offset.zero, ancestor: overlayBox);
    final panelTop = offset.dy + box.size.height + 8;
    final panelWidth = math.min(320.0, overlayBox.size.width - 24);
    final panelRight =
        overlayBox.size.width - (offset.dx + box.size.width);

    showDialog<void>(
      context: context,
      barrierColor: Colors.black26,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final hasUnread =
                alerts.any((alert) => !_readAlertIds.contains(alert.id));

            void refreshDialog() {
              setState(() {});
              setDialogState(() {});
            }

            return Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(dialogContext),
                    behavior: HitTestBehavior.opaque,
                    child: const SizedBox.expand(),
                  ),
                ),
                Positioned(
                  top: panelTop,
                  right: panelRight.clamp(12.0, overlayBox.size.width),
                  width: panelWidth,
                  child: Material(
                    elevation: 8,
                    shadowColor: Colors.black26,
                    color: const Color(0xFFFDFCFA),
                    borderRadius: BorderRadius.circular(16),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 360),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Notifications',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                if (hasUnread)
                                  TextButton(
                                    onPressed: () {
                                      _markAllAlertsRead(alerts);
                                      refreshDialog();
                                    },
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text(
                                      'Mark all read',
                                      style: TextStyle(fontSize: 11),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            if (alerts.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  'No budget alerts right now. You\'re all clear.',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                  ),
                                ),
                              )
                            else
                              ...alerts.map((alert) {
                                final isRead = _readAlertIds.contains(alert.id);
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isRead
                                        ? const Color(0xFFFAFAF8)
                                        : const Color(0xFFF3F1EB),
                                    borderRadius: BorderRadius.circular(12),
                                    border: isRead
                                        ? Border.all(
                                            color: const Color(0xFFE8E4DC),
                                          )
                                        : null,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Icon(
                                            alert.level == 'over'
                                                ? Icons.error_outline
                                                : Icons.warning_amber_rounded,
                                            size: 18,
                                            color: alert.level == 'over'
                                                ? Colors.red
                                                : Colors.orange,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  alert.title,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 12,
                                                    color: isRead
                                                        ? Colors.grey
                                                        : Colors.black,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  alert.body,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: isRead
                                                        ? Colors.grey.shade500
                                                        : Colors.grey,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (!isRead) ...[
                                        const SizedBox(height: 8),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: TextButton(
                                            onPressed: () {
                                              _markAlertRead(alert.id);
                                              refreshDialog();
                                            },
                                            style: TextButton.styleFrom(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              minimumSize: Size.zero,
                                              tapTargetSize: MaterialTapTargetSize
                                                  .shrinkWrap,
                                            ),
                                            child: const Text(
                                              'Mark as read',
                                              style: TextStyle(fontSize: 11),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              }),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddTransactionSheet() {
    return _showQuickAddDialog();
  }

  Widget _quickTypeButton(String label, bool selected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF151311) : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: selected ? Colors.white : const Color(0xFF6D6962),
          ),
        ),
      ),
    );
  }

  void _showQuickAddDialog() {
    final now = DateTime.now();
    final todayLabel =
        '${now.month.toString().padLeft(2, '0')}/'
        '${now.day.toString().padLeft(2, '0')}/'
        '${now.year}';
    final amountController = TextEditingController(text: '0.00');
    final noteController = TextEditingController();
    final dateController = TextEditingController(text: todayLabel);
    TxKind kind = TxKind.expense;
    String category = 'Food';
    final categories = CATEGORIES.map((c) => c.name).toList();

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 24,
          ),
          backgroundColor: const Color(0xFFFDFCFA),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: Responsive.contentMaxWidth(context).clamp(320, 560),
              maxHeight: MediaQuery.of(context).size.height * 0.88,
            ),
            child: SingleChildScrollView(
              child: StatefulBuilder(
                builder: (context, setSheetState) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Quick add',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Log it in a few taps — no backend needed yet.',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0EEE9),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _quickTypeButton(
                                  'Expense',
                                  kind == TxKind.expense,
                                  () => setSheetState(
                                    () => kind = TxKind.expense,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: _quickTypeButton(
                                  'Income',
                                  kind == TxKind.income,
                                  () =>
                                      setSheetState(() => kind = TxKind.income),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: amountController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Amount',
                            prefixText: '₱ ',
                            filled: true,
                            fillColor: const Color(0xFFF0EEE9),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(999),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          children: [
                            ActionChip(
                              avatar: const Icon(
                                Icons.star,
                                size: 14,
                                color: Colors.amber,
                              ),
                              label: const Text('Bus fare · ₱80'),
                              onPressed: () {
                                amountController.text = '80';
                                noteController.text = 'Bus fare';
                              },
                            ),
                            ActionChip(
                              avatar: const Icon(
                                Icons.star,
                                size: 14,
                                color: Colors.amber,
                              ),
                              label: const Text('Rice bowl · ₱120'),
                              onPressed: () {
                                amountController.text = '120';
                                noteController.text = 'Rice bowl';
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: categories
                              .map(
                                (item) => ChoiceChip(
                                  label: Text(item),
                                  selected: category == item,
                                  selectedColor: const Color(0xFFFF7F20),
                                  labelStyle: TextStyle(
                                    color: category == item
                                        ? Colors.white
                                        : Colors.grey.shade700,
                                  ),
                                  onSelected: (_) =>
                                      setSheetState(() => category = item),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: dateController,
                                readOnly: true,
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2100),
                                    initialDate: DateTime.now(),
                                  );
                                  if (picked != null) {
                                    dateController.text =
                                        '${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}';
                                  }
                                },
                                decoration: const InputDecoration(
                                  labelText: 'Date',
                                  suffixIcon: Icon(
                                    Icons.calendar_today_outlined,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: noteController,
                                decoration: const InputDecoration(
                                  labelText: 'Note',
                                  hintText: 'Optional',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () {
                              final result = validateAmount(
                                amountController.text,
                              );
                              if (!result.ok) {
                                _showMessage(
                                  result.message ??
                                      'Enter a valid amount greater than 0.',
                                );
                                return;
                              }

                              _addTransaction(
                                buildTransaction(
                                  kind: kind,
                                  amountText: amountController.text,
                                  category: category,
                                  dateText: dateController.text,
                                  note: noteController.text,
                                ),
                              );
                              Navigator.of(context).pop();
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Save expense'),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
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
      padding: _pagePadding(context),
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
                      child: Row(
                        children: [
                          const Icon(
                            Icons.arrow_upward_rounded,
                            size: 14,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${totals.income == 0 ? 0 : ((totals.balance / totals.income) * 100).round()}%',
                            style: const TextStyle(
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
                BalanceAreaSparkline(
                  values: balanceSparkline(_transactions),
                  color: Colors.green,
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
    final sorted = filterTransactions(
      _transactions,
      query: _transactionQuery,
      filter: _transactionFilter,
    );
    final spent = sorted
        .where((tx) => tx.kind == TxKind.expense)
        .fold<double>(0, (sum, tx) => sum + tx.amount);
    final earned = sorted
        .where((tx) => tx.kind == TxKind.income)
        .fold<double>(0, (sum, tx) => sum + tx.amount);

    return ListView(
      padding: _pagePadding(context),
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
              for (final filter in const [
                'Today',
                'This Week',
                'This Month',
                'All',
              ])
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
                        onTap: () => _confirmRemoveTransaction(tx.id),
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
      padding: _pagePadding(context),
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
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFDFCFA),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 14,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
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
                        onPressed: () => _confirmRemoveBudget(budget.id),
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                        ),
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
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFDFCFA),
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 14,
                offset: const Offset(0, 7),
              ),
            ],
          ),
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
                LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 360;
                    final fields = Row(
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
                          width: compact ? 88 : 110,
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
                    );
                    return fields;
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        const _SectionHeader(title: 'Savings goals'),
        const SizedBox(height: 12),
        ..._goals.map(
          (goal) => Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        goal.title,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        '${(goal.current / goal.target * 100).round()}%',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: (goal.current / goal.target).clamp(0.0, 1.0),
                    minHeight: 9,
                    borderRadius: BorderRadius.circular(999),
                    color: const Color(0xFF22AE98),
                    backgroundColor: Colors.grey.shade200,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${peso(goal.current)} / ${peso(goal.target)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => _contributeGoal(goal.id),
                      child: const Text('+ ₱500'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _goalTitleController,
                decoration: const InputDecoration(hintText: 'New goal'),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 112,
              child: TextField(
                controller: _goalTargetController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(hintText: 'Target'),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _addGoal,
              icon: const Icon(Icons.add),
              tooltip: 'Add goal',
            ),
          ],
        ),
      ],
    );
  }

  Widget _analyticsView() {
    final totals = monthlyTotals(_transactions);
    final sorted = spentByCategory(_transactions).entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topCategory = sorted.isNotEmpty ? sorted.first.key : '—';
    final monthExpenses = _transactions
        .where((tx) => tx.kind == TxKind.expense && isThisMonth(tx.date))
        .toList();
    final bars = weeklyBars(_transactions);
    final trend = monthlyTrend(_transactions);
    final totalSpent = totals.expenses <= 0 ? 1.0 : totals.expenses;

    return ListView(
      padding: _pagePadding(context),
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
                  'Spending by category',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final stackChart = constraints.maxWidth < 420;
                    final chart = CategoryPieChart(
                      slices: sorted.take(6).toList(),
                      size: stackChart ? 112 : 128,
                    );
                    final legend = Column(
                      children: [
                        ...sorted.take(6).map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 7),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 5,
                                  backgroundColor: _colorFromHex(
                                    categoryOf(item.key).color,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    item.key,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                                Text(
                                  '${(item.value / totalSpent * 100).round()}%',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (sorted.isEmpty)
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'No expenses this month yet.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                      ],
                    );

                    if (stackChart) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(child: chart),
                          const SizedBox(height: 12),
                          legend,
                        ],
                      );
                    }

                    return Row(
                      children: [
                        chart,
                        const SizedBox(width: 12),
                        Expanded(child: legend),
                      ],
                    );
                  },
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
                  'Spending this month',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  '${peso(totals.expenses)} across ${monthExpenses.length} entries',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                WeeklyBarChart(bars: bars),
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
                  '6-month trend',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                TrendSparkline(points: trend),
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
                  'Top spending categories',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                if (sorted.isEmpty)
                  const Text(
                    'No spending data yet.',
                    style: TextStyle(color: Colors.grey),
                  )
                else
                  ...sorted.take(5).map(
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
    final favorites = _transactions.where((tx) => tx.favorite).toList();
    final score = healthScore(_transactions, _budgets);
    final healthLabel = score >= 75
        ? 'Excellent'
        : score >= 60
        ? 'Good'
        : 'Needs attention';
    final email = _user?.email ?? '';
    final currency = _user?.currency;
    final employment = _user?.employmentStatus;

    return ListView(
      padding: _pagePadding(context),
      children: [
        Card(
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(0xFFF39A42),
                  child: Text(
                    _initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _displayName,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (email.isNotEmpty)
                        Text(
                          email,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      Text(
                        'Wallet health $score · $healthLabel',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      if (currency != null || employment != null)
                        Text(
                          [
                            if (currency != null && currency.isNotEmpty)
                              currency,
                            if (employment != null && employment.isNotEmpty)
                              employment,
                          ].join(' · '),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF8A857C),
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _loggingOut ? null : _confirmLogout,
                  tooltip: 'Sign out',
                  icon: _loggingOut
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.logout_rounded, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _loggingOut ? null : _confirmLogout,
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: Text(_loggingOut ? 'Signing out...' : 'Sign out'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF5C564C),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
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
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🏆  Achievements',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  'Essential Spending Streak: ${essentialStreak(_transactions)} days',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: const [
                    _AchievementTile(
                      icon: '🌱',
                      title: 'Smart Starter',
                      subtitle: '3-day streak',
                      unlocked: true,
                    ),
                    _AchievementTile(
                      icon: '🛡️',
                      title: 'Budget Keeper',
                      subtitle: '7-day streak',
                    ),
                    _AchievementTile(
                      icon: '🧠',
                      title: 'Wise Spender',
                      subtitle: '14-day streak',
                    ),
                    _AchievementTile(
                      icon: '👑',
                      title: 'Financial Master',
                      subtitle: '30-day streak',
                    ),
                  ],
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
                  '🔔  Budget Buddy alerts',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEDC5),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    budgetAlerts(_transactions, _budgets).isEmpty
                        ? 'Your budgets are on track.'
                        : budgetAlerts(_transactions, _budgets).first.body,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children:
                [
                      'Daily expense reminder',
                      'Budget threshold alerts',
                      'Streak celebrations',
                      'Biometric lock',
                    ]
                    .map(
                      (label) => SwitchListTile(
                        title: Text(
                          label,
                          style: const TextStyle(fontSize: 13),
                        ),
                        value: _settings[label] ?? false,
                        onChanged: (value) =>
                            setState(() => _settings[label] = value),
                      ),
                    )
                    .toList(),
          ),
        ),
      ],
    );
  }

  EdgeInsets _pagePadding(BuildContext context) =>
      Responsive.pagePadding(context);

  Widget _buildAppHeader(int alertCount) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          Responsive.pagePadding(context).left,
          10,
          Responsive.pagePadding(context).right,
          8,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: const Color(0xFFF39A42),
              child: Text(
                _initial,
                style: const TextStyle(
                  color: Colors.white,
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
                  Text(
                    'Hi, $_greetingName',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
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
                      MaterialLocalizations.of(context).formatMediumDate(
                        DateTime.now(),
                      ),
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                ],
              ),
            ),
            Builder(
              builder: (buttonContext) => Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    onPressed: () => _showNotifications(buttonContext),
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
                          color: Color(0xFFFF7F20),
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationRail() {
    return NavigationRail(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) => setState(() => _selectedIndex = index),
      labelType: NavigationRailLabelType.all,
      backgroundColor: const Color(0xFFFDFCFA),
      selectedIconTheme: const IconThemeData(color: Color(0xFFFF7F20)),
      selectedLabelTextStyle: const TextStyle(
        color: Color(0xFF1F1F1F),
        fontWeight: FontWeight.w700,
        fontSize: 11,
      ),
      unselectedLabelTextStyle: const TextStyle(
        color: Color(0xFF77736C),
        fontSize: 11,
      ),
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: Text('Home'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long),
          label: Text('Activity'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.account_balance_wallet_outlined),
          selectedIcon: Icon(Icons.account_balance_wallet),
          label: Text('Budgets'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.insights_outlined),
          selectedIcon: Icon(Icons.insights),
          label: Text('Insights'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: Text('Profile'),
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Material(
        elevation: 2,
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
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
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFFFF7F20),
                    shape: const CircleBorder(
                      side: BorderSide(color: Color(0xFFFF7F20), width: 4),
                    ),
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
                color: selected
                    ? const Color(0xFFFF7F20)
                    : const Color(0xFF77736C),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? const Color(0xFF1F1F1F)
                      : const Color(0xFF77736C),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(List<Widget> pages) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: Responsive.contentMaxWidth(context),
        ),
        child: IndexedStack(index: _selectedIndex, children: pages),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingFinance) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFFF7F20)),
        ),
      );
    }

    final pages = [
      _dashboardView(),
      _transactionsView(),
      _budgetsView(),
      _analyticsView(),
      _profileView(),
    ];

    final alertCount = unreadAlertCount(
      budgetAlerts(_transactions, _budgets),
      _readAlertIds,
    );
    final useSideNav = Responsive.useSideNav(context);

    if (useSideNav) {
      return Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: _showAddTransactionSheet,
          tooltip: 'Quick add',
          backgroundColor: const Color(0xFFFF7F20),
          foregroundColor: Colors.white,
          child: const Icon(Icons.add),
        ),
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildNavigationRail(),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildAppHeader(alertCount),
                  Expanded(child: _buildMainContent(pages)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(78),
        child: _buildAppHeader(alertCount),
      ),
      body: _buildMainContent(pages),
      bottomNavigationBar: _buildBottomNav(),
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

class _AchievementTile extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final bool unlocked;

  const _AchievementTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.unlocked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: (Responsive.contentMaxWidth(context).clamp(280.0, 960.0) - 80) / 2,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: unlocked ? const Color(0xFFD5F3EA) : const Color(0xFFF3F1ED),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: unlocked ? Colors.black : Colors.grey,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

Color _colorFromHex(String hexString) {
  final cleaned = hexString.replaceFirst('#', '');
  final value = cleaned.length == 6 ? cleaned : 'FF$cleaned';
  return Color(int.parse(value, radix: 16) + 0xFF000000);
}
