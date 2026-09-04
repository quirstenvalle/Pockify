class AuthUser {
  final String id;
  final String name;
  final String email;
  final String passwordHash;
  final String passwordSalt;
  final bool emailVerified;
  final String? currency;
  final String? employmentStatus;
  final DateTime? birthDate;
  final double? monthlyIncome;
  final double? monthlyBudgetGoal;
  final DateTime createdAt;

  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.passwordHash,
    required this.passwordSalt,
    required this.emailVerified,
    this.currency,
    this.employmentStatus,
    this.birthDate,
    this.monthlyIncome,
    this.monthlyBudgetGoal,
    required this.createdAt,
  });

  AuthUser copyWith({
    String? name,
    String? email,
    String? passwordHash,
    String? passwordSalt,
    bool? emailVerified,
    String? currency,
    String? employmentStatus,
    DateTime? birthDate,
    double? monthlyIncome,
    double? monthlyBudgetGoal,
  }) {
    return AuthUser(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      passwordSalt: passwordSalt ?? this.passwordSalt,
      emailVerified: emailVerified ?? this.emailVerified,
      currency: currency ?? this.currency,
      employmentStatus: employmentStatus ?? this.employmentStatus,
      birthDate: birthDate ?? this.birthDate,
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      monthlyBudgetGoal: monthlyBudgetGoal ?? this.monthlyBudgetGoal,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'passwordHash': passwordHash,
    'passwordSalt': passwordSalt,
    'emailVerified': emailVerified,
    'currency': currency,
    'employmentStatus': employmentStatus,
    'birthDate': birthDate?.toIso8601String(),
    'monthlyIncome': monthlyIncome,
    'monthlyBudgetGoal': monthlyBudgetGoal,
    'createdAt': createdAt.toIso8601String(),
  };

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
    id: json['id'] as String,
    name: json['name'] as String,
    email: json['email'] as String,
    passwordHash: json['passwordHash'] as String? ?? '',
    passwordSalt: json['passwordSalt'] as String? ?? '',
    emailVerified: json['emailVerified'] as bool? ?? false,
    currency: json['currency'] as String?,
    employmentStatus: json['employmentStatus'] as String?,
    birthDate: json['birthDate'] == null
        ? null
        : DateTime.tryParse(json['birthDate'] as String),
    monthlyIncome: (json['monthlyIncome'] as num?)?.toDouble(),
    monthlyBudgetGoal: (json['monthlyBudgetGoal'] as num?)?.toDouble(),
    createdAt: DateTime.parse(
      json['createdAt'] as String? ?? DateTime.now().toIso8601String(),
    ),
  );

  factory AuthUser.fromApiJson(Map<String, dynamic> json) => AuthUser(
    id: '${json['id']}',
    name: json['name'] as String? ?? '',
    email: (json['email'] as String? ?? '').toLowerCase(),
    passwordHash: '',
    passwordSalt: '',
    emailVerified: json['email_verified'] as bool? ?? false,
    currency: json['currency'] as String?,
    employmentStatus: json['employment_status'] as String?,
    birthDate: json['birth_date'] == null
        ? null
        : DateTime.tryParse('${json['birth_date']}'),
    monthlyIncome: (json['monthly_income'] as num?)?.toDouble(),
    monthlyBudgetGoal: (json['monthly_budget_goal'] as num?)?.toDouble(),
    createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
        DateTime.now(),
  );
}

class PendingSignup {
  final String name;
  final String email;
  final String password;
  final String? currency;
  final String? employmentStatus;
  final DateTime? birthDate;
  final double? monthlyIncome;
  final double? monthlyBudgetGoal;

  const PendingSignup({
    required this.name,
    required this.email,
    required this.password,
    this.currency,
    this.employmentStatus,
    this.birthDate,
    this.monthlyIncome,
    this.monthlyBudgetGoal,
  });

  PendingSignup copyWith({
    String? name,
    String? email,
    String? password,
  }) {
    return PendingSignup(
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      currency: currency,
      employmentStatus: employmentStatus,
      birthDate: birthDate,
      monthlyIncome: monthlyIncome,
      monthlyBudgetGoal: monthlyBudgetGoal,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'password': password,
    'currency': currency,
    'employmentStatus': employmentStatus,
    'birthDate': birthDate?.toIso8601String(),
    'monthlyIncome': monthlyIncome,
    'monthlyBudgetGoal': monthlyBudgetGoal,
  };

  factory PendingSignup.fromJson(Map<String, dynamic> json) => PendingSignup(
    name: json['name'] as String? ?? '',
    email: (json['email'] as String? ?? '').toLowerCase(),
    password: json['password'] as String? ?? '',
    currency: json['currency'] as String?,
    employmentStatus: json['employmentStatus'] as String?,
    birthDate: json['birthDate'] == null
        ? null
        : DateTime.tryParse(json['birthDate'] as String),
    monthlyIncome: (json['monthlyIncome'] as num?)?.toDouble(),
    monthlyBudgetGoal: (json['monthlyBudgetGoal'] as num?)?.toDouble(),
  );
}

class EmailVerificationChallenge {
  final String email;
  final String codeHash;
  final String salt;
  final DateTime expiresAt;
  final DateTime createdAt;
  final int attempts;
  final DateTime? lastSentAt;

  const EmailVerificationChallenge({
    required this.email,
    required this.codeHash,
    required this.salt,
    required this.expiresAt,
    required this.createdAt,
    this.attempts = 0,
    this.lastSentAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Duration get remaining => expiresAt.difference(DateTime.now());

  EmailVerificationChallenge copyWith({
    String? codeHash,
    String? salt,
    DateTime? expiresAt,
    DateTime? createdAt,
    int? attempts,
    DateTime? lastSentAt,
  }) {
    return EmailVerificationChallenge(
      email: email,
      codeHash: codeHash ?? this.codeHash,
      salt: salt ?? this.salt,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
      attempts: attempts ?? this.attempts,
      lastSentAt: lastSentAt ?? this.lastSentAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'email': email,
    'codeHash': codeHash,
    'salt': salt,
    'expiresAt': expiresAt.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'attempts': attempts,
    'lastSentAt': lastSentAt?.toIso8601String(),
  };

  factory EmailVerificationChallenge.fromJson(Map<String, dynamic> json) =>
      EmailVerificationChallenge(
        email: json['email'] as String,
        codeHash: json['codeHash'] as String,
        salt: json['salt'] as String,
        expiresAt: DateTime.parse(json['expiresAt'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
        attempts: json['attempts'] as int? ?? 0,
        lastSentAt: json['lastSentAt'] == null
            ? null
            : DateTime.parse(json['lastSentAt'] as String),
      );
}

enum AuthFailureCode {
  invalidCredentials,
  emailTaken,
  emailNotFound,
  emailUnverified,
  invalidCode,
  expiredCode,
  tooManyAttempts,
  resendCooldown,
  invalidEmail,
}

class AuthException implements Exception {
  final AuthFailureCode code;
  final String message;

  const AuthException(this.code, this.message);

  @override
  String toString() => message;
}

class AuthResult {
  final bool ok;
  final AuthUser? user;
  final AuthFailureCode? failureCode;
  final String? message;
  final bool requiresVerification;
  final String? demoCode;
  final String? token;
  final bool redirecting;

  const AuthResult({
    required this.ok,
    this.user,
    this.failureCode,
    this.message,
    this.requiresVerification = false,
    this.demoCode,
    this.token,
    this.redirecting = false,
  });

  factory AuthResult.success(
    AuthUser user, {
    String? demoCode,
    String? token,
  }) => AuthResult(
    ok: true,
    user: user,
    demoCode: demoCode,
    token: token,
  );

  factory AuthResult.redirecting() => const AuthResult(
    ok: false,
    redirecting: true,
    message: 'Continue in the Google window to finish signing in.',
  );

  factory AuthResult.failure(
    AuthFailureCode code,
    String message, {
    bool requiresVerification = false,
    String? demoCode,
    AuthUser? user,
    String? token,
  }) => AuthResult(
    ok: false,
    failureCode: code,
    message: message,
    requiresVerification: requiresVerification,
    demoCode: demoCode,
    user: user,
    token: token,
  );
}
