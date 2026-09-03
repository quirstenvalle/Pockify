import 'dart:async';

import 'package:flutter/material.dart';

import '../auth/auth_models.dart';
import '../auth/auth_service.dart';
import '../responsive.dart';
import '../widgets/otp_input_row.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({
    super.key,
    required this.email,
    required this.onVerified,
    required this.onBackToAuth,
    this.initialDemoCode,
  });

  final String email;
  final VoidCallback onVerified;
  final VoidCallback onBackToAuth;
  final String? initialDemoCode;

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final _auth = AuthService.instance;
  final _otpKey = GlobalKey<OtpInputRowState>();
  final _emailEditController = TextEditingController();

  late String _email;
  String _otp = '';
  String? _statusMessage;
  String? _errorMessage;
  String? _demoCode;
  bool _busy = false;
  bool _editingEmail = false;
  bool _success = false;
  Duration _remaining = AuthService.otpTtl;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _email = widget.email.trim().toLowerCase();
    _emailEditController.text = _email;
    _demoCode = widget.initialDemoCode;
    _statusMessage =
        "We've sent a verification code to $_email. Enter it below to finish signing up.";
    _startTicker();
    _refreshRemaining();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _emailEditController.dispose();
    super.dispose();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) async {
      await _refreshRemaining();
    });
  }

  Future<void> _refreshRemaining() async {
    final remaining = await _auth.remainingOtpTime(_email);
    if (!mounted) return;
    setState(() {
      _remaining = remaining ?? Duration.zero;
      if (_remaining <= Duration.zero && _errorMessage == null && !_success) {
        _errorMessage =
            'This verification code has expired. Request a new one.';
      }
    });
  }

  String _formatDuration(Duration d) {
    if (d <= Duration.zero) return '00:00';
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _verify() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _errorMessage = null;
      _statusMessage = null;
    });

    final result = await _auth.verifyEmail(email: _email, code: _otp);
    if (!mounted) return;

    if (result.ok) {
      setState(() {
        _busy = false;
        _success = true;
        _statusMessage = 'Email verified successfully.';
        _errorMessage = null;
        _demoCode = null;
      });

      await showGeneralDialog<void>(
        context: context,
        barrierDismissible: false,
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
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Color(0xFF16A34A),
                          size: 48,
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Sign up successful',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Your email is verified. You are now signed in.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
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
                            child: const Text('Continue'),
                          ),
                        ),
                      ],
                    ),
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

      if (!mounted) return;
      widget.onVerified();
      return;
    }

    setState(() {
      _busy = false;
      _errorMessage = result.message;
      if (result.failureCode == AuthFailureCode.invalidCode ||
          result.failureCode == AuthFailureCode.tooManyAttempts) {
          _otpKey.currentState?.clear();
          _otp = '';
      }
    });
  }

  Future<void> _resend() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _errorMessage = null;
      _statusMessage = null;
    });

    final result = await _auth.resendVerificationCode(email: _email);
    if (!mounted) return;

    setState(() {
      _busy = false;
      if (result.failureCode == AuthFailureCode.resendCooldown) {
        _errorMessage = result.message;
      } else if (result.ok || result.requiresVerification) {
        _statusMessage = "We've sent a new verification code to your email.";
        _errorMessage = null;
        _demoCode = result.demoCode;
          _otpKey.currentState?.clear();
          _otp = '';
        _remaining = AuthService.otpTtl;
      } else {
        _errorMessage = result.message;
      }
    });
    await _refreshRemaining();
  }

  Future<void> _saveEmailChange() async {
    final next = _emailEditController.text.trim().toLowerCase();
    if (next.isEmpty || !next.contains('@')) {
      setState(() => _errorMessage = 'Enter a valid email address.');
      return;
    }

    setState(() {
      _busy = true;
      _errorMessage = null;
    });

    final result = await _auth.updatePendingEmail(
      currentEmail: _email,
      newEmail: next,
    );
    if (!mounted) return;

    setState(() {
      _busy = false;
      if (result.requiresVerification || result.ok) {
        _email = next;
        _editingEmail = false;
        _statusMessage = "We've sent a verification code to your email address.";
        _demoCode = result.demoCode;
          _otpKey.currentState?.clear();
          _otp = '';
        _remaining = AuthService.otpTtl;
      } else {
        _errorMessage = result.message;
      }
    });
    await _refreshRemaining();
  }

  @override
  Widget build(BuildContext context) {
    final expired = _remaining <= Duration.zero;

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
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _busy ? null : widget.onBackToAuth,
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: const Text('Back to sign in'),
                ),
              ),
              const SizedBox(height: 8),
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
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Icon(
                            Icons.mark_email_unread_outlined,
                            size: 42,
                            color: Color(0xFFFF7F20),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Verify your email',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _statusMessage ??
                                "We've sent a verification code to your email address.",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6D6962),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_editingEmail) ...[
                            TextField(
                              controller: _emailEditController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                hintText: 'name@example.com',
                                prefixIcon: Icon(Icons.mail_outline, size: 18),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _busy
                                        ? null
                                        : () => setState(() {
                                            _editingEmail = false;
                                            _emailEditController.text = _email;
                                          }),
                                    child: const Text('Cancel'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: FilledButton(
                                    onPressed: _busy ? null : _saveEmailChange,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFFFF7F20),
                                    ),
                                    child: const Text('Update & resend'),
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F1EB),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.mail_outline,
                                    size: 16,
                                    color: Color(0xFF6D6962),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _email,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: _busy
                                        ? null
                                        : () => setState(
                                            () => _editingEmail = true,
                                          ),
                                    child: const Text(
                                      'Change',
                                      style: TextStyle(fontSize: 11),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              const Text(
                                'Enter 6-digit code',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                expired
                                    ? 'Expired'
                                    : 'Expires in ${_formatDuration(_remaining)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: expired
                                      ? Colors.red
                                      : const Color(0xFF6D6962),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          OtpInputRow(
                            key: _otpKey,
                            length: AuthService.otpLength,
                            enabled: !_busy && !_success,
                            onChanged: (value) => setState(() => _otp = value),
                          ),
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 12),
                            _Banner(
                              text: _errorMessage!,
                              tone: _BannerTone.error,
                            ),
                          ],
                          if (_success) ...[
                            const SizedBox(height: 12),
                            const _Banner(
                              text: 'Email verified. Welcome to Pockify!',
                              tone: _BannerTone.success,
                            ),
                          ],
                          if (_demoCode != null && !_success) ...[
                            const SizedBox(height: 12),
                            _Banner(
                              text:
                                  'Demo inbox (no SMTP configured): your code is $_demoCode',
                              tone: _BannerTone.info,
                            ),
                          ],
                          const SizedBox(height: 18),
                          FilledButton(
                            onPressed: _busy ||
                                    _success ||
                                    _otp.length != AuthService.otpLength
                                ? null
                                : _verify,
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
                                : const Text('Verify Email'),
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton(
                            onPressed: _busy || _success ? null : _resend,
                            child: const Text('Resend Code'),
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
}

enum _BannerTone { info, error, success }

class _Banner extends StatelessWidget {
  const _Banner({required this.text, required this.tone});

  final String text;
  final _BannerTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = switch (tone) {
      _BannerTone.info => (
        bg: const Color(0xFFFFF4E8),
        fg: const Color(0xFF9A5A12),
      ),
      _BannerTone.error => (
        bg: const Color(0xFFFFECEC),
        fg: const Color(0xFFB42318),
      ),
      _BannerTone.success => (
        bg: const Color(0xFFE8F8F2),
        fg: const Color(0xFF0F7A55),
      ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: colors.fg,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          height: 1.35,
        ),
      ),
    );
  }
}
