import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../auth/auth_repository.dart';
import '../core/constants.dart';
import '../profile/editable_profile.dart';
import '../shared/circul_header.dart';

enum WelcomeAuthProvider { google, apple }

enum WelcomeAuthOutcome { existingAccount, needsAccount }

const _emailVerificationCodeLength = 8;

abstract class WelcomeAuthService {
  Future<WelcomeAuthOutcome> continueWithProvider(WelcomeAuthProvider provider);

  Future<EditableProfile> signInWithEmail({
    required String email,
    required String password,
  });

  Future<void> resendEmailVerification(String email);

  Future<void> verifyEmailOtp({required String email, required String token});

  Future<EditableProfile> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    required String username,
  });

  Future<bool> isEmailTaken(String email);

  Future<bool> isUsernameTaken(String username);
}

class PlaceholderWelcomeAuthService implements WelcomeAuthService {
  const PlaceholderWelcomeAuthService();

  @override
  Future<WelcomeAuthOutcome> continueWithProvider(
    WelcomeAuthProvider provider,
  ) async {
    return WelcomeAuthOutcome.existingAccount;
  }

  @override
  Future<EditableProfile> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return UserRepositoryDefaults.profile;
  }

  @override
  Future<void> resendEmailVerification(String email) async {}

  @override
  Future<void> verifyEmailOtp({
    required String email,
    required String token,
  }) async {}

  @override
  Future<EditableProfile> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    required String username,
  }) async {
    return EditableProfile(
      name: name.trim(),
      username: username.trim().replaceFirst(RegExp(r'^@+'), ''),
      bio: '',
      location: '',
    );
  }

  @override
  Future<bool> isUsernameTaken(String username) async => false;

  @override
  Future<bool> isEmailTaken(String email) async => false;
}

class WelcomeAuthRepositoryAdapter implements WelcomeAuthService {
  const WelcomeAuthRepositoryAdapter(this.repository);

  final AuthRepository repository;

  @override
  Future<WelcomeAuthOutcome> continueWithProvider(
    WelcomeAuthProvider provider,
  ) async {
    throw const AuthFailure('Login Google/Apple belum tersedia di versi ini.');
  }

  @override
  Future<EditableProfile> signInWithEmail({
    required String email,
    required String password,
  }) {
    return repository.signInWithEmail(email: email, password: password);
  }

  @override
  Future<void> resendEmailVerification(String email) {
    return repository.resendEmailVerification(email);
  }

  @override
  Future<void> verifyEmailOtp({required String email, required String token}) {
    return repository.verifyEmailOtp(email: email, token: token);
  }

  @override
  Future<EditableProfile> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    required String username,
  }) {
    return repository.signUpWithEmail(
      email: email,
      password: password,
      name: name,
      username: username,
    );
  }

  @override
  Future<bool> isUsernameTaken(String username) async {
    final cleanUsername = username.trim().replaceFirst(RegExp(r'^@+'), '');
    if (cleanUsername.isEmpty) return false;
    return repository.isUsernameTaken(cleanUsername);
  }

  @override
  Future<bool> isEmailTaken(String email) async {
    final cleanEmail = email.trim();
    if (cleanEmail.isEmpty) return false;
    return repository.isEmailTaken(cleanEmail);
  }
}

class UnavailableWelcomeAuthService implements WelcomeAuthService {
  const UnavailableWelcomeAuthService();

  @override
  Future<WelcomeAuthOutcome> continueWithProvider(
    WelcomeAuthProvider provider,
  ) async {
    throw const AuthFailure('Supabase belum dikonfigurasi.');
  }

  @override
  Future<EditableProfile> signInWithEmail({
    required String email,
    required String password,
  }) async {
    throw const AuthFailure('Supabase belum dikonfigurasi.');
  }

  @override
  Future<void> resendEmailVerification(String email) async {
    throw const AuthFailure('Supabase belum dikonfigurasi.');
  }

  @override
  Future<void> verifyEmailOtp({
    required String email,
    required String token,
  }) async {
    throw const AuthFailure('Supabase belum dikonfigurasi.');
  }

  @override
  Future<EditableProfile> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    required String username,
  }) async {
    throw const AuthFailure('Supabase belum dikonfigurasi.');
  }

  @override
  Future<bool> isUsernameTaken(String username) async {
    throw const AuthFailure('Supabase belum dikonfigurasi.');
  }

  @override
  Future<bool> isEmailTaken(String email) async {
    throw const AuthFailure('Supabase belum dikonfigurasi.');
  }
}

class UserRepositoryDefaults {
  const UserRepositoryDefaults._();

  static const profile = EditableProfile(
    name: 'Sarah Mae',
    username: 'sarahmae',
    bio:
        'Berusaha hidup lebih berkelanjutan \u{1F33F}\nBelajar, berbagi, dan berdampak.',
    location: 'Jakarta, Indonesia',
  );
}

class WelcomeFlow extends StatefulWidget {
  const WelcomeFlow({
    super.key,
    required this.onComplete,
    this.authService = const PlaceholderWelcomeAuthService(),
  });

  final VoidCallback onComplete;
  final WelcomeAuthService authService;

  @override
  State<WelcomeFlow> createState() => _WelcomeFlowState();
}

class _WelcomeFlowState extends State<WelcomeFlow> {
  static const _transitionDuration = Duration(milliseconds: 300);

  var _step = _WelcomeStep.welcome;
  var _transitionDirection = 1;
  var _isSubmitting = false;
  var _isCheckingUsername = false;
  var _isUsernameTaken = false;
  var _hasCheckedUsername = false;
  var _usernameLookupId = 0;
  String? _errorMessage;
  Timer? _usernameCheckTimer;
  List<String> _usernameSuggestions = const [];
  final _history = <_WelcomeStep>[];
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailVerificationCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _usernameController.addListener(_queueUsernameAvailabilityCheck);
  }

  @override
  void dispose() {
    _usernameCheckTimer?.cancel();
    _usernameController.removeListener(_queueUsernameAvailabilityCheck);
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _emailController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    _emailVerificationCodeController.dispose();
    super.dispose();
  }

  void _go(_WelcomeStep step) {
    setState(() {
      _transitionDirection = 1;
      _history.add(_step);
      _step = step;
      _errorMessage = null;
    });
  }

  void _back() {
    if (_history.isEmpty) return;
    setState(() {
      _transitionDirection = -1;
      _step = _history.removeLast();
      _errorMessage = null;
    });
  }

  Future<void> _continueWithProvider(WelcomeAuthProvider provider) async {
    await _submit(() async {
      final outcome = await widget.authService.continueWithProvider(provider);
      if (outcome == WelcomeAuthOutcome.existingAccount) {
        widget.onComplete();
      } else {
        _go(_WelcomeStep.createAccount);
      }
    });
  }

  Future<void> _submitSignIn() async {
    final email = _loginEmailController.text.trim();
    final password = _loginPasswordController.text;
    final validationError = _validateEmailPassword(email, password);
    if (validationError != null) {
      setState(() => _errorMessage = validationError);
      return;
    }

    await _submit(() async {
      try {
        await widget.authService.signInWithEmail(
          email: email,
          password: password,
        );
      } on AuthEmailVerificationPending catch (error) {
        _emailController.text = error.email;
        _emailVerificationCodeController.clear();
        _go(_WelcomeStep.emailVerification);
        return;
      }
      widget.onComplete();
    });
  }

  Future<void> _continueCreateAccount() async {
    final email = _emailController.text.trim();
    final name = _nameController.text.trim();
    if (!_isValidEmail(email)) {
      setState(() => _errorMessage = 'Masukkan email yang valid.');
      return;
    }
    if (name.isEmpty) {
      setState(() => _errorMessage = 'Nama wajib diisi.');
      return;
    }

    await _submit(() async {
      final isTaken = await widget.authService.isEmailTaken(email);
      if (isTaken) {
        throw const AuthFailure('Email already exist, please login.');
      }
      _go(_WelcomeStep.createPassword);
    });
  }

  void _continueCreatePassword() {
    final passwordSecurity = _PasswordSecurity.evaluate(
      _passwordController.text,
    );
    if (!passwordSecurity.meetsRequiredRules) {
      setState(
        () => _errorMessage =
            'Password harus memenuhi semua security requirements wajib.',
      );
      return;
    }
    _go(_WelcomeStep.username);
  }

  Future<void> _submitSignUp() async {
    final username = _cleanUsername(_usernameController.text);
    if (!_isValidUsernameFormat(username)) {
      setState(
        () => _errorMessage =
            'Username 3-24 karakter: huruf, angka, titik, atau underscore.',
      );
      return;
    }

    await _submit(() async {
      final isTaken = await widget.authService.isUsernameTaken(username);
      if (isTaken) {
        throw const AuthFailure('Username sudah dipakai.');
      }
      await widget.authService.signUpWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        username: username,
      );
      _go(_WelcomeStep.emailVerification);
    });
  }

  Future<bool> _resendEmailVerification() async {
    final email = _emailController.text.trim();
    if (!_isValidEmail(email)) {
      setState(() => _errorMessage = 'Masukkan email yang valid.');
      return false;
    }

    try {
      await widget.authService.resendEmailVerification(email);
      if (!mounted) return false;
      setState(() => _errorMessage = 'Email verification sent.');
      return true;
    } catch (error) {
      if (!mounted) return false;
      setState(() => _errorMessage = _messageFromError(error));
      return false;
    }
  }

  Future<void> _verifyEmailCode() async {
    final email = _emailController.text.trim();
    final token = _emailVerificationCodeController.text.trim();
    if (!_isValidEmail(email)) {
      setState(() => _errorMessage = 'Masukkan email yang valid.');
      return;
    }
    if (!RegExp(r'^\d{8}$').hasMatch(token)) {
      setState(() => _errorMessage = 'Masukkan kode verifikasi 8 digit.');
      return;
    }

    await _submit(() async {
      await widget.authService.verifyEmailOtp(email: email, token: token);
      widget.onComplete();
    });
  }

  void _queueUsernameAvailabilityCheck() {
    _usernameCheckTimer?.cancel();
    final lookupId = ++_usernameLookupId;
    final username = _cleanUsername(_usernameController.text);

    if (!_isValidUsernameFormat(username)) {
      setState(() {
        _isCheckingUsername = false;
        _isUsernameTaken = false;
        _hasCheckedUsername = false;
        _usernameSuggestions = const [];
      });
      return;
    }

    setState(() {
      _isCheckingUsername = true;
      _isUsernameTaken = false;
      _hasCheckedUsername = false;
      _usernameSuggestions = const [];
    });

    _usernameCheckTimer = Timer(const Duration(milliseconds: 350), () {
      _checkUsernameAvailability(username, lookupId);
    });
  }

  Future<void> _checkUsernameAvailability(String username, int lookupId) async {
    try {
      final isTaken = await widget.authService.isUsernameTaken(username);
      if (!mounted || lookupId != _usernameLookupId) return;

      if (!isTaken) {
        setState(() {
          _isCheckingUsername = false;
          _isUsernameTaken = false;
          _hasCheckedUsername = true;
          _usernameSuggestions = const [];
        });
        return;
      }

      final suggestions = <String>[];
      for (final suggestion in _candidateUsernameSuggestions(username)) {
        final suggestionTaken = await widget.authService.isUsernameTaken(
          suggestion,
        );
        if (!mounted || lookupId != _usernameLookupId) return;
        if (!suggestionTaken) suggestions.add(suggestion);
        if (suggestions.length == 4) break;
      }

      setState(() {
        _isCheckingUsername = false;
        _isUsernameTaken = true;
        _hasCheckedUsername = true;
        _usernameSuggestions = suggestions;
      });
    } catch (error) {
      if (!mounted || lookupId != _usernameLookupId) return;
      setState(() {
        _isCheckingUsername = false;
        _isUsernameTaken = false;
        _hasCheckedUsername = false;
        _usernameSuggestions = const [];
      });
    }
  }

  void _selectUsernameSuggestion(String suggestion) {
    _usernameController.text = suggestion;
    _usernameController.selection = TextSelection.collapsed(
      offset: suggestion.length,
    );
  }

  Future<void> _submit(Future<void> Function() action) async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      await action();
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = _messageFromError(error));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String? _validateEmailPassword(String email, String password) {
    if (!_isValidEmail(email)) return 'Masukkan email yang valid.';
    if (password.isEmpty) return 'Password wajib diisi.';
    return null;
  }

  String _cleanUsername(String value) {
    return value.trim().replaceFirst(RegExp(r'^@+'), '');
  }

  bool _isValidUsernameFormat(String username) {
    return RegExp(r'^[a-zA-Z0-9._]{3,24}$').hasMatch(username);
  }

  List<String> _candidateUsernameSuggestions(String username) {
    final cleanBase = username.replaceAll(RegExp(r'[^a-zA-Z0-9._]'), '');
    final base = cleanBase.isEmpty ? 'circul' : cleanBase;
    const suffixes = ['01', '08', '20', '24', '_id', '.id', '_go', '.go'];
    final suggestions = <String>[];

    for (final suffix in suffixes) {
      final maxBaseLength = 24 - suffix.length;
      final trimmedBase = base.length > maxBaseLength
          ? base.substring(0, maxBaseLength)
          : base;
      final suggestion = '$trimmedBase$suffix';
      if (_isValidUsernameFormat(suggestion)) suggestions.add(suggestion);
    }

    return suggestions.toSet().toList(growable: false);
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }

  String _messageFromError(Object error) {
    if (error is AuthFailure) return error.message;
    return error.toString();
  }

  @override
  Widget build(BuildContext context) {
    final screen = switch (_step) {
      _WelcomeStep.welcome => _WelcomeScreen(
        onStart: () => _go(_WelcomeStep.loginMethod),
      ),
      _WelcomeStep.loginMethod => _LoginMethodScreen(
        onEmail: () => _go(_WelcomeStep.emailLogin),
        onGoogle: () => _continueWithProvider(WelcomeAuthProvider.google),
        onApple: () => _continueWithProvider(WelcomeAuthProvider.apple),
        onCreateAccount: () => _go(_WelcomeStep.createAccount),
        errorMessage: _errorMessage,
      ),
      _WelcomeStep.emailLogin => _EmailLoginScreen(
        emailController: _loginEmailController,
        passwordController: _loginPasswordController,
        onBack: _back,
        onLogin: _submitSignIn,
        isLoading: _isSubmitting,
        errorMessage: _errorMessage,
      ),
      _WelcomeStep.createAccount => _CreateAccountScreen(
        onBack: _back,
        emailController: _emailController,
        nameController: _nameController,
        onCreateAccount: () => _continueCreateAccount(),
        onLogin: () => _go(_WelcomeStep.loginMethod),
        isLoading: _isSubmitting,
        errorMessage: _errorMessage,
      ),
      _WelcomeStep.verifyMethod => _VerifyMethodScreen(
        onBack: _back,
        onEmail: () => _go(_WelcomeStep.emailVerification),
        onWhatsapp: () => _go(_WelcomeStep.phoneNumber),
      ),
      _WelcomeStep.phoneNumber => _PhoneNumberScreen(
        onBack: _back,
        onSendCode: () => _go(_WelcomeStep.whatsappVerification),
      ),
      _WelcomeStep.emailVerification => _OtpVerificationScreen.email(
        onBack: _back,
        emailAddress: _emailController.text.trim(),
        verificationCodeController: _emailVerificationCodeController,
        onVerify: _verifyEmailCode,
        onResendEmail: _resendEmailVerification,
        message: _errorMessage,
        isLoading: _isSubmitting,
      ),
      _WelcomeStep.whatsappVerification => _OtpVerificationScreen.whatsapp(
        onBack: _back,
        onVerify: () => _go(_WelcomeStep.createPassword),
      ),
      _WelcomeStep.createPassword => _CreatePasswordScreen(
        onBack: _back,
        passwordController: _passwordController,
        onCreateAccount: _continueCreatePassword,
        errorMessage: _errorMessage,
      ),
      _WelcomeStep.username => _UsernameScreen(
        onBack: _back,
        usernameController: _usernameController,
        onContinue: _submitSignUp,
        isLoading: _isSubmitting,
        isCheckingUsername: _isCheckingUsername,
        isUsernameTaken: _isUsernameTaken,
        hasCheckedUsername: _hasCheckedUsername,
        usernameSuggestions: _usernameSuggestions,
        onSuggestionSelected: _selectUsernameSuggestion,
        errorMessage: _errorMessage,
      ),
    };

    return AnimatedSwitcher(
      duration: _transitionDuration,
      switchInCurve: Curves.fastOutSlowIn,
      switchOutCurve: Curves.fastOutSlowIn,
      transitionBuilder: (child, animation) {
        final isIncoming = child.key == ValueKey(_step);
        final direction = _transitionDirection.toDouble();
        final slide = Tween<Offset>(
          begin: Offset(isIncoming ? direction : -direction, 0),
          end: Offset.zero,
        ).animate(animation);

        return ClipRect(
          child: SlideTransition(position: slide, child: child),
        );
      },
      child: KeyedSubtree(key: ValueKey(_step), child: screen),
    );
  }
}

enum _WelcomeStep {
  welcome,
  loginMethod,
  emailLogin,
  createAccount,
  verifyMethod,
  phoneNumber,
  emailVerification,
  whatsappVerification,
  createPassword,
  username,
}

class _PasswordSecurity {
  const _PasswordSecurity({
    required this.hasMinimumLength,
    required this.hasLowercase,
    required this.hasUppercase,
    required this.hasDigit,
    required this.hasSpecialCharacter,
  });

  factory _PasswordSecurity.evaluate(String password) {
    return _PasswordSecurity(
      hasMinimumLength: password.length >= 8,
      hasLowercase: RegExp(r'[a-z]').hasMatch(password),
      hasUppercase: RegExp(r'[A-Z]').hasMatch(password),
      hasDigit: RegExp(r'\d').hasMatch(password),
      hasSpecialCharacter: RegExp(r'[^A-Za-z0-9]').hasMatch(password),
    );
  }

  final bool hasMinimumLength;
  final bool hasLowercase;
  final bool hasUppercase;
  final bool hasDigit;
  final bool hasSpecialCharacter;

  bool get meetsRequiredRules {
    return hasMinimumLength && hasLowercase && hasUppercase && hasDigit;
  }

  int get requiredRulesMet {
    return [
      hasMinimumLength,
      hasLowercase,
      hasUppercase,
      hasDigit,
    ].where((met) => met).length;
  }

  double get meterValue {
    if (meetsRequiredRules) return hasSpecialCharacter ? 1 : .9;
    return requiredRulesMet * .2;
  }

  String get meterLabel {
    if (meetsRequiredRules && hasSpecialCharacter) return 'EXCELLENT';
    if (meetsRequiredRules) return 'STRONG';
    if (requiredRulesMet >= 3) return 'GOOD';
    if (requiredRulesMet >= 2) return 'FAIR';
    return 'WEAK';
  }

  Color get meterColor {
    if (meetsRequiredRules) return kCirculGreen;
    if (requiredRulesMet >= 2) return const Color(0xFFE7A31A);
    return const Color(0xFFE5484D);
  }
}

class _PasswordRequirement {
  const _PasswordRequirement({
    required this.label,
    required this.isMet,
    this.isBonus = false,
  });

  final String label;
  final bool isMet;
  final bool isBonus;
}

class _WelcomeScreen extends StatelessWidget {
  const _WelcomeScreen({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return _WelcomeScaffold(
      topPadding: 16,
      scrollBody: false,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const CirculFullLogo(height: 30),
                const Spacer(),
                IconButton(
                  tooltip: 'Help',
                  onPressed: () {},
                  icon: const Icon(Icons.help_outline_rounded, size: 26),
                ),
              ],
            ),
          ),
          const Spacer(flex: 2),
          Image.asset(
            'assets/images/welcome_cleanup.png',
            width: 360,
            fit: BoxFit.contain,
          ),
          const Spacer(flex: 1),
          const Text(
            'Welcome to Circul',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Join our community in making the world\ncleaner, one check-in at a time.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF3F4944),
                fontSize: 16,
                height: 1.55,
              ),
            ),
          ),
          const Spacer(flex: 2),
        ],
      ),
      bottom: _WelcomePrimaryButton(
        label: 'Start Check-in',
        icon: Icons.arrow_forward_rounded,
        onPressed: onStart,
      ),
    );
  }
}

class _LoginMethodScreen extends StatelessWidget {
  const _LoginMethodScreen({
    required this.onEmail,
    required this.onGoogle,
    required this.onApple,
    required this.onCreateAccount,
    this.errorMessage,
  });

  final VoidCallback onEmail;
  final VoidCallback onGoogle;
  final VoidCallback onApple;
  final VoidCallback onCreateAccount;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return _WelcomeScaffold(
      background: const LinearGradient(
        colors: [Color(0xFFEAF7EF), Colors.white, Color(0xFFE7F5EF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      scrollBody: false,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            const Spacer(flex: 2),
            const CirculFullLogo(height: 52),
            const SizedBox(height: 22),
            const Text(
              'Join the movement to protect our natural\nspaces and build a cleaner future.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF45504C),
                fontSize: 15.5,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 66),
            _AuthButton(
              label: 'Login using Google account',
              onPressed: onGoogle,
              leading: const _GoogleMark(),
            ),
            const SizedBox(height: 18),
            _AuthButton(
              label: 'Login using Apple account',
              onPressed: onApple,
              leading: const Icon(Icons.apple_rounded, color: Colors.white),
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              borderColor: Colors.black,
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 18),
              _WelcomeErrorText(errorMessage!),
            ],
            const SizedBox(height: 34),
            const _OrDivider(),
            const SizedBox(height: 36),
            _AuthButton(
              label: 'Login using Email',
              onPressed: onEmail,
              leading: const Icon(
                Icons.mail_outline_rounded,
                color: Colors.white,
              ),
              backgroundColor: kCirculGreen,
              foregroundColor: Colors.white,
              borderColor: kCirculGreen,
            ),
            const Spacer(flex: 3),
            TextButton(
              onPressed: onCreateAccount,
              style: TextButton.styleFrom(foregroundColor: kCirculGreen),
              child: const Text.rich(
                TextSpan(
                  text: 'New to Circul? ',
                  style: TextStyle(color: Color(0xFF45504C)),
                  children: [
                    TextSpan(
                      text: 'Create an account',
                      style: TextStyle(color: kCirculGreen),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _CreateAccountScreen extends StatelessWidget {
  const _CreateAccountScreen({
    required this.onBack,
    required this.emailController,
    required this.nameController,
    required this.onCreateAccount,
    required this.onLogin,
    required this.isLoading,
    this.errorMessage,
  });

  final VoidCallback onBack;
  final TextEditingController emailController;
  final TextEditingController nameController;
  final VoidCallback onCreateAccount;
  final VoidCallback onLogin;
  final bool isLoading;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return _WelcomeScaffold(
      header: _BackHeader(onBack: onBack),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            const SizedBox(height: 56),
            const CirculLogo(size: 56),
            const SizedBox(height: 18),
            const Text(
              'Create Account',
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            const Text(
              'Join the community driving real environmental impact.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF45504C), fontSize: 15),
            ),
            const SizedBox(height: 40),
            _WelcomeField(
              label: 'Email Address',
              hint: 'name@example.com',
              icon: Icons.mail_outline_rounded,
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 22),
            _WelcomeField(
              label: 'Full Name',
              hint: 'Jane Doe',
              icon: Icons.person_outline_rounded,
              controller: nameController,
              textCapitalization: TextCapitalization.words,
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 18),
              _WelcomeErrorText(errorMessage!),
            ],
          ],
        ),
      ),
      bottom: Column(
        children: [
          _WelcomePrimaryButton(
            label: isLoading ? 'Checking...' : 'Create Account',
            onPressed: onCreateAccount,
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onLogin,
            child: const Text.rich(
              TextSpan(
                text: 'Already have an account? ',
                style: TextStyle(color: Color(0xFF59635E)),
                children: [
                  TextSpan(
                    text: 'Login',
                    style: TextStyle(color: kCirculGreen),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          const _LegalText(
            text:
                "By creating an account, you agree to EcoAction's Terms\nof Service and Privacy Policy.",
          ),
        ],
      ),
    );
  }
}

class _EmailLoginScreen extends StatelessWidget {
  const _EmailLoginScreen({
    required this.emailController,
    required this.passwordController,
    required this.onBack,
    required this.onLogin,
    required this.isLoading,
    this.errorMessage,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final VoidCallback onBack;
  final VoidCallback onLogin;
  final bool isLoading;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return _WelcomeScaffold(
      header: _BackHeader(onBack: onBack),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 42),
            const _ScreenTitle(
              title: 'Login using email',
              subtitle: 'Enter your Circul account email and password.',
            ),
            const SizedBox(height: 30),
            _WelcomeField(
              label: 'Email Address',
              hint: 'name@example.com',
              icon: Icons.mail_outline_rounded,
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 18),
            _WelcomeField(
              label: 'Password',
              hint: 'Password',
              icon: Icons.lock_outline_rounded,
              controller: passwordController,
              obscureText: true,
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 18),
              _WelcomeErrorText(errorMessage!),
            ],
          ],
        ),
      ),
      bottom: _WelcomePrimaryButton(
        label: isLoading ? 'Loading...' : 'Login',
        onPressed: onLogin,
      ),
    );
  }
}

class _VerifyMethodScreen extends StatelessWidget {
  const _VerifyMethodScreen({
    required this.onBack,
    required this.onEmail,
    required this.onWhatsapp,
  });

  final VoidCallback onBack;
  final VoidCallback onEmail;
  final VoidCallback onWhatsapp;

  @override
  Widget build(BuildContext context) {
    return _WelcomeScaffold(
      header: _BackHeader(onBack: onBack),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            SizedBox(height: 36),
            _ScreenTitle(
              title: 'Verify your account',
              subtitle:
                  "Choose how you'd like to receive your\nverification code.",
            ),
          ],
        ),
      ),
      bottom: Column(
        children: [
          _AuthButton(
            label: 'Using email',
            onPressed: onEmail,
            leading: const _PaleIcon(icon: Icons.mail_outline_rounded),
          ),
          const SizedBox(height: 16),
          _AuthButton(
            label: 'Whatsapp Number',
            onPressed: onWhatsapp,
            leading: const _PaleIcon(
              icon: Icons.chat_bubble_outline_rounded,
              dark: true,
            ),
            backgroundColor: kCirculGreen,
            foregroundColor: Colors.white,
            borderColor: kCirculGreen,
          ),
        ],
      ),
    );
  }
}

class _PhoneNumberScreen extends StatelessWidget {
  const _PhoneNumberScreen({required this.onBack, required this.onSendCode});

  final VoidCallback onBack;
  final VoidCallback onSendCode;

  @override
  Widget build(BuildContext context) {
    return _WelcomeScaffold(
      header: _BackHeader(onBack: onBack),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            SizedBox(height: 58),
            _ScreenTitle(
              title: 'Input Phone Number',
              subtitle:
                  'Make sure the phone number is active and\nconnected to whatsapp',
            ),
            SizedBox(height: 28),
            _PhoneField(),
          ],
        ),
      ),
      bottom: Column(
        children: [
          _WelcomePrimaryButton(label: 'Send Code', onPressed: onSendCode),
          const SizedBox(height: 16),
          const _LegalText(
            text: "By continuing, you agree to Circul's Terms of Service.",
            muted: true,
          ),
        ],
      ),
    );
  }
}

class _OtpVerificationScreen extends StatefulWidget {
  const _OtpVerificationScreen.email({
    required this.onBack,
    required this.emailAddress,
    required this.verificationCodeController,
    required this.onVerify,
    required this.onResendEmail,
    required this.isLoading,
    this.message,
  }) : isWhatsapp = false;

  const _OtpVerificationScreen.whatsapp({
    required this.onBack,
    required this.onVerify,
  }) : emailAddress = '',
       verificationCodeController = null,
       onResendEmail = null,
       isLoading = false,
       message = null,
       isWhatsapp = true;

  final bool isWhatsapp;
  final String emailAddress;
  final TextEditingController? verificationCodeController;
  final VoidCallback onBack;
  final VoidCallback onVerify;
  final Future<bool> Function()? onResendEmail;
  final bool isLoading;
  final String? message;

  @override
  State<_OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<_OtpVerificationScreen> {
  static const _resendCooldownSeconds = 60;

  Timer? _resendTimer;
  var _remainingSeconds = _resendCooldownSeconds;
  var _isResending = false;

  @override
  void initState() {
    super.initState();
    widget.verificationCodeController?.addListener(_refreshVerifyButton);
    if (!widget.isWhatsapp) _startResendCooldown();
  }

  @override
  void didUpdateWidget(covariant _OtpVerificationScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.verificationCodeController !=
        widget.verificationCodeController) {
      oldWidget.verificationCodeController?.removeListener(
        _refreshVerifyButton,
      );
      widget.verificationCodeController?.addListener(_refreshVerifyButton);
    }
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    widget.verificationCodeController?.removeListener(_refreshVerifyButton);
    super.dispose();
  }

  void _refreshVerifyButton() {
    if (mounted) setState(() {});
  }

  void _startResendCooldown() {
    _resendTimer?.cancel();
    setState(() => _remainingSeconds = _resendCooldownSeconds);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() => _remainingSeconds = 0);
        return;
      }
      setState(() => _remainingSeconds--);
    });
  }

  Future<void> _resendEmail() async {
    final resend = widget.onResendEmail;
    if (resend == null || _remainingSeconds > 0 || _isResending) return;

    setState(() => _isResending = true);
    final sent = await resend();
    if (!mounted) return;
    setState(() => _isResending = false);
    if (sent) _startResendCooldown();
  }

  String get _remainingLabel {
    final minutes = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  bool get _canVerify {
    if (widget.isLoading) return false;
    if (widget.isWhatsapp) return true;

    final token = widget.verificationCodeController?.text.trim() ?? '';
    return RegExp(r'^\d{8}$').hasMatch(token);
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isWhatsapp ? 'Verify your phone' : 'Verify your email';
    final verificationEmail = widget.emailAddress.isEmpty
        ? 'your email'
        : widget.emailAddress;
    final subtitle = widget.isWhatsapp
        ? "We've sent a 6-digit verification code to\n+62 8000-0000 via WhatsApp."
        : "We've sent an 8-digit verification code to\n$verificationEmail. Enter it below to continue.";

    return _WelcomeScaffold(
      header: widget.isWhatsapp
          ? _BackHeader(onBack: widget.onBack)
          : _BackLogoHeader(onBack: widget.onBack),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: widget.isWhatsapp ? 58 : 70),
            _ScreenTitle(title: title, subtitle: subtitle),
            const SizedBox(height: 32),
            if (widget.isWhatsapp)
              const _OtpBoxes()
            else
              _VerificationCodeField(
                controller: widget.verificationCodeController!,
              ),
            if (!widget.isWhatsapp) ...[
              const SizedBox(height: 18),
              const Center(
                child: Icon(
                  Icons.mark_email_read_outlined,
                  color: kCirculGreen,
                  size: 46,
                ),
              ),
            ],
            const SizedBox(height: 28),
            Center(
              child: Text(
                widget.isWhatsapp
                    ? "Didn't receive the code? Resend code"
                    : "Didn't receive the email?",
                style: TextStyle(
                  color: widget.isWhatsapp
                      ? kCirculGreen
                      : const Color(0xFF3F4944),
                  fontSize: 15,
                ),
              ),
            ),
            if (!widget.isWhatsapp) ...[
              const SizedBox(height: 10),
              Center(
                child: TextButton.icon(
                  onPressed: _remainingSeconds == 0 && !_isResending
                      ? _resendEmail
                      : null,
                  icon: Icon(
                    Icons.refresh_rounded,
                    size: 17,
                    color: _remainingSeconds == 0 && !_isResending
                        ? kCirculGreen
                        : const Color(0xFF9CA3AF),
                  ),
                  label: Text(
                    _isResending
                        ? 'Sending...'
                        : _remainingSeconds > 0
                        ? 'Request new email in $_remainingLabel'
                        : 'Request new email',
                    style: TextStyle(
                      color: _remainingSeconds == 0 && !_isResending
                          ? kCirculGreen
                          : const Color(0xFF9CA3AF),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              if (widget.message != null) ...[
                const SizedBox(height: 12),
                _VerificationMessage(widget.message!),
              ],
            ],
          ],
        ),
      ),
      bottom: Column(
        children: [
          _WelcomePrimaryButton(
            label: widget.isLoading ? 'Verifying...' : 'Verify Code',
            onPressed: _canVerify ? widget.onVerify : null,
            backgroundColor: widget.isWhatsapp
                ? kCirculGreen
                : const Color(0xFF8AAE9F),
          ),
          if (widget.isWhatsapp) ...[
            const SizedBox(height: 16),
            const _LegalText(
              text: "By continuing, you agree to Circul's Terms of Service.",
              muted: true,
            ),
          ],
        ],
      ),
    );
  }
}

class _CreatePasswordScreen extends StatelessWidget {
  const _CreatePasswordScreen({
    required this.onBack,
    required this.passwordController,
    required this.onCreateAccount,
    this.errorMessage,
  });

  final VoidCallback onBack;
  final TextEditingController passwordController;
  final VoidCallback onCreateAccount;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return _WelcomeScaffold(
      header: _BackHeader(onBack: onBack),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 42),
            const _ScreenTitle(
              title: 'Create a password',
              subtitle: 'Set a secure password for your account.',
            ),
            const SizedBox(height: 30),
            _PasswordField(controller: passwordController),
            const SizedBox(height: 18),
            _PasswordStrength(controller: passwordController),
            if (errorMessage != null) ...[
              const SizedBox(height: 18),
              _WelcomeErrorText(errorMessage!),
            ],
            const SizedBox(height: 28),
            _RequirementCard(controller: passwordController),
          ],
        ),
      ),
      bottom: Column(
        children: [
          _WelcomePrimaryButton(
            label: 'Create Account',
            icon: Icons.arrow_forward_rounded,
            onPressed: onCreateAccount,
          ),
          const SizedBox(height: 16),
          const _LegalText(
            text: 'By creating an account, you agree to our Terms of Service.',
          ),
        ],
      ),
    );
  }
}

class _VerificationMessage extends StatelessWidget {
  const _VerificationMessage(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    final isError =
        message.toLowerCase().contains('gagal') ||
        message.toLowerCase().contains('error') ||
        message.toLowerCase().contains('supabase') ||
        message.toLowerCase().contains('invalid') ||
        message.toLowerCase().contains('kedaluwarsa');
    final color = isError ? const Color(0xFFFF3857) : kCirculGreen;

    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.check_circle_rounded,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VerificationCodeField extends StatelessWidget {
  const _VerificationCodeField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(_emailVerificationCodeLength),
      ],
      maxLength: _emailVerificationCodeLength,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: kInk,
        fontSize: 24,
        fontWeight: FontWeight.w900,
        letterSpacing: 0,
      ),
      decoration: InputDecoration(
        counterText: '',
        hintText: '00000000',
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        border: _fieldBorder(),
        enabledBorder: _fieldBorder(),
        focusedBorder: _fieldBorder(color: kCirculGreen, width: 1.4),
      ),
    );
  }
}

class _UsernameScreen extends StatelessWidget {
  const _UsernameScreen({
    required this.onBack,
    required this.usernameController,
    required this.onContinue,
    required this.isLoading,
    required this.isCheckingUsername,
    required this.isUsernameTaken,
    required this.hasCheckedUsername,
    required this.usernameSuggestions,
    required this.onSuggestionSelected,
    this.errorMessage,
  });

  final VoidCallback onBack;
  final TextEditingController usernameController;
  final VoidCallback onContinue;
  final bool isLoading;
  final bool isCheckingUsername;
  final bool isUsernameTaken;
  final bool hasCheckedUsername;
  final List<String> usernameSuggestions;
  final ValueChanged<String> onSuggestionSelected;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return _WelcomeScaffold(
      header: _BackHeader(onBack: onBack),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 58),
            const _ScreenTitle(
              title: 'Choose your username',
              subtitle: 'This is how your friends will find you on Circul.',
            ),
            const SizedBox(height: 36),
            _PlainInput(hint: '@ username', controller: usernameController),
            if (isCheckingUsername) ...[
              const SizedBox(height: 12),
              const Text(
                'Checking username...',
                style: TextStyle(
                  color: Color(0xFF59635E),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            if (hasCheckedUsername && !isCheckingUsername) ...[
              const SizedBox(height: 14),
              _UsernameAvailabilityNote(isAvailable: !isUsernameTaken),
            ],
            if (errorMessage != null) ...[
              const SizedBox(height: 14),
              _WelcomeErrorText(errorMessage!),
            ],
            if (isUsernameTaken) ...[
              const SizedBox(height: 20),
              _UsernameSuggestions(
                suggestions: usernameSuggestions,
                onSelected: onSuggestionSelected,
              ),
            ],
          ],
        ),
      ),
      bottom: _WelcomePrimaryButton(
        label: isLoading ? 'Loading...' : 'Continue',
        onPressed: onContinue,
      ),
    );
  }
}

class _WelcomeScaffold extends StatelessWidget {
  const _WelcomeScaffold({
    required this.body,
    this.bottom,
    this.header,
    this.background,
    this.topPadding = 0,
    this.scrollBody = true,
  });

  final Widget body;
  final Widget? bottom;
  final Widget? header;
  final Gradient? background;
  final double topPadding;
  final bool scrollBody;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFC),
      body: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFFAFBFC),
          gradient: background,
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.only(top: topPadding),
            child: Column(
              children: [
                ?header,
                Expanded(
                  child: _EntranceMotion(
                    delay: const Duration(milliseconds: 70),
                    child: scrollBody
                        ? LayoutBuilder(
                            builder: (context, constraints) {
                              return SingleChildScrollView(
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minHeight: constraints.maxHeight,
                                  ),
                                  child: body,
                                ),
                              );
                            },
                          )
                        : body,
                  ),
                ),
                if (bottom case final bottom?)
                  _EntranceMotion(
                    delay: const Duration(milliseconds: 130),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                      child: bottom,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EntranceMotion extends StatefulWidget {
  const _EntranceMotion({required this.child, this.delay = Duration.zero});

  final Widget child;
  final Duration delay;

  @override
  State<_EntranceMotion> createState() => _EntranceMotionState();
}

class _EntranceMotionState extends State<_EntranceMotion>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(curve);

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future<void>.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _opacity, child: widget.child);
  }
}

class _BackLogoHeader extends StatelessWidget {
  const _BackLogoHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: Row(
        children: [
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Back',
            onPressed: onBack,
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Color(0xFF075734),
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          const CirculFullLogo(height: 28),
        ],
      ),
    );
  }
}

class _BackHeader extends StatelessWidget {
  const _BackHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: IconButton(
            tooltip: 'Back',
            onPressed: onBack,
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Color(0xFF075734),
              size: 26,
            ),
          ),
        ),
      ),
    );
  }
}

class _ScreenTitle extends StatelessWidget {
  const _ScreenTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            textAlign: TextAlign.left,
            style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            textAlign: TextAlign.left,
            style: const TextStyle(
              color: Color(0xFF45504C),
              fontSize: 16,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeErrorText extends StatelessWidget {
  const _WelcomeErrorText(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.error_outline_rounded, color: Color(0xFFFF3857)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              color: Color(0xFFFF3857),
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}

class _WelcomePrimaryButton extends StatelessWidget {
  const _WelcomePrimaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.backgroundColor = kCirculGreen,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: backgroundColor,
        disabledBackgroundColor: const Color(0xFFC7D0CB),
        disabledForegroundColor: Colors.white,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(56),
        elevation: 8,
        shadowColor: const Color(0x330B5133),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800),
          ),
          if (icon != null) ...[const SizedBox(width: 8), Icon(icon, size: 21)],
        ],
      ),
    );
  }
}

class _AuthButton extends StatelessWidget {
  const _AuthButton({
    required this.label,
    required this.onPressed,
    required this.leading,
    this.backgroundColor = Colors.white,
    this.foregroundColor = kInk,
    this.borderColor = const Color(0xFFC8D1CC),
  });

  final String label;
  final VoidCallback onPressed;
  final Widget leading;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          side: BorderSide(color: borderColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 28, child: Center(child: leading)),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: foregroundColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'G',
      style: TextStyle(
        color: Color(0xFF4285F4),
        fontSize: 21,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(child: Divider(color: Color(0xFFC7D0CB))),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 18),
          child: Text('or', style: TextStyle(color: Color(0xFF68736D))),
        ),
        Expanded(child: Divider(color: Color(0xFFC7D0CB))),
      ],
    );
  }
}

class _WelcomeField extends StatelessWidget {
  const _WelcomeField({
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.obscureText = false,
  });

  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    final field = obscureText
        ? _PasswordTextField(
            controller: controller,
            hintText: hint,
            prefixIcon: icon,
          )
        : TextField(
            controller: controller,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: Icon(icon, color: Color(0xFF76817C)),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 18,
                horizontal: 16,
              ),
              border: _fieldBorder(),
              enabledBorder: _fieldBorder(),
              focusedBorder: _fieldBorder(color: kCirculGreen, width: 1.4),
            ),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF4B5550),
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        field,
      ],
    );
  }
}

class _PlainInput extends StatelessWidget {
  const _PlainInput({required this.hint, required this.controller});

  final String hint;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 20,
        ),
        border: _fieldBorder(),
        enabledBorder: _fieldBorder(),
        focusedBorder: _fieldBorder(color: kCirculGreen, width: 1.4),
      ),
    );
  }
}

class _PhoneField extends StatelessWidget {
  const _PhoneField();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: TextField(
        keyboardType: TextInputType.phone,
        decoration: InputDecoration(
          hintText: '+62   8000-0000',
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 16, right: 8),
            child: _IndonesiaFlag(),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 46),
          filled: true,
          fillColor: Colors.white,
          border: _fieldBorder(),
          enabledBorder: _fieldBorder(),
          focusedBorder: _fieldBorder(color: kCirculGreen, width: 1.4),
        ),
      ),
    );
  }
}

class _IndonesiaFlag extends StatelessWidget {
  const _IndonesiaFlag();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 14,
      height: 10,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Expanded(child: ColoredBox(color: Color(0xFFFF3B3B))),
          Expanded(child: ColoredBox(color: Colors.white)),
        ],
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return _PasswordTextField(controller: controller);
  }
}

class _PasswordTextField extends StatelessWidget {
  const _PasswordTextField({
    required this.controller,
    this.hintText,
    this.prefixIcon,
  });

  final TextEditingController controller;
  final String? hintText;
  final IconData? prefixIcon;

  @override
  Widget build(BuildContext context) {
    return _PasswordVisibilityField(
      controller: controller,
      hintText: hintText,
      prefixIcon: prefixIcon,
      useFormField: true,
    );
  }
}

class _PasswordVisibilityField extends StatefulWidget {
  const _PasswordVisibilityField({
    required this.controller,
    required this.useFormField,
    this.hintText,
    this.prefixIcon,
  });

  final TextEditingController controller;
  final bool useFormField;
  final String? hintText;
  final IconData? prefixIcon;

  @override
  State<_PasswordVisibilityField> createState() =>
      _PasswordVisibilityFieldState();
}

class _PasswordVisibilityFieldState extends State<_PasswordVisibilityField> {
  var _isObscured = true;

  @override
  Widget build(BuildContext context) {
    final decoration = InputDecoration(
      hintText: widget.hintText,
      prefixIcon: widget.prefixIcon == null
          ? null
          : Icon(widget.prefixIcon, color: const Color(0xFF76817C)),
      suffixIcon: IconButton(
        tooltip: _isObscured ? 'Show password' : 'Hide password',
        onPressed: () => setState(() => _isObscured = !_isObscured),
        icon: Icon(
          _isObscured
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
        ),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: _fieldBorder(),
      enabledBorder: _fieldBorder(),
      focusedBorder: _fieldBorder(color: kCirculGreen, width: 1.4),
    );

    if (widget.useFormField) {
      return TextFormField(
        controller: widget.controller,
        obscureText: _isObscured,
        decoration: decoration,
      );
    }

    return TextField(
      controller: widget.controller,
      obscureText: _isObscured,
      decoration: decoration,
    );
  }
}

class _PasswordStrength extends StatelessWidget {
  const _PasswordStrength({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        final security = _PasswordSecurity.evaluate(value.text);
        final percent = (security.meterValue * 100).round();

        return Column(
          children: [
            Row(
              children: [
                Text(
                  security.meterLabel,
                  style: TextStyle(
                    color: security.meterColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(),
                Text(
                  '$percent% Secure',
                  style: const TextStyle(
                    color: Color(0xFF3F4944),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: security.meterValue,
                minHeight: 6,
                backgroundColor: const Color(0xFFE1E5E3),
                color: security.meterColor,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RequirementCard extends StatelessWidget {
  const _RequirementCard({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        final security = _PasswordSecurity.evaluate(value.text);
        final items = [
          _PasswordRequirement(
            label: 'Minimum 8 characters',
            isMet: security.hasMinimumLength,
          ),
          _PasswordRequirement(
            label: 'At least one lowercase letter',
            isMet: security.hasLowercase,
          ),
          _PasswordRequirement(
            label: 'At least one uppercase letter',
            isMet: security.hasUppercase,
          ),
          _PasswordRequirement(
            label: 'At least one numeric digit',
            isMet: security.hasDigit,
          ),
          _PasswordRequirement(
            label: 'Special characters (Bonus)',
            isMet: security.hasSpecialCharacter,
            isBonus: true,
          ),
        ];

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE8ECEA)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'SECURITY REQUIREMENTS',
                style: TextStyle(
                  color: Color(0xFF3F4944),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 18),
              for (final item in items) ...[
                _RequirementRow(item: item),
                if (item != items.last) const SizedBox(height: 16),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _RequirementRow extends StatelessWidget {
  const _RequirementRow({required this.item});

  final _PasswordRequirement item;

  @override
  Widget build(BuildContext context) {
    final color = item.isMet ? kCirculGreen : const Color(0xFF9CA3AF);
    final icon = item.isBonus
        ? (item.isMet ? Icons.stars_rounded : Icons.stars_outlined)
        : (item.isMet
              ? Icons.check_circle_rounded
              : Icons.radio_button_unchecked_rounded);

    return Row(
      children: [
        Icon(icon, color: color, size: 19),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            item.label,
            style: TextStyle(
              color: item.isMet ? kInk : const Color(0xFF5F6964),
              fontSize: 14,
              fontWeight: item.isBonus ? FontWeight.w800 : null,
            ),
          ),
        ),
      ],
    );
  }
}

class _OtpBoxes extends StatelessWidget {
  const _OtpBoxes();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var index = 0; index < 6; index++)
          Expanded(
            child: Container(
              height: 60,
              margin: EdgeInsets.only(right: index == 5 ? 0 : 2),
              decoration: BoxDecoration(
                color: const Color(0xFFE9E9EA),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Center(
                child: Text(
                  '-',
                  style: TextStyle(
                    color: Color(0xFF667085),
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _UsernameSuggestions extends StatelessWidget {
  const _UsernameSuggestions({
    required this.suggestions,
    required this.onSelected,
  });

  final List<String> suggestions;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8ECEA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pick Our Recommendation',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 18),
          if (suggestions.isEmpty)
            const Text(
              'No available recommendation yet.',
              style: TextStyle(color: Color(0xFF59635E), fontSize: 14),
            )
          else
            for (final suggestion in suggestions) ...[
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => onSelected(suggestion),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: kCirculGreen,
                          size: 19,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            suggestion,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Color(0xFF59635E),
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (suggestion != suggestions.last) const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }
}

class _UsernameAvailabilityNote extends StatelessWidget {
  const _UsernameAvailabilityNote({required this.isAvailable});

  final bool isAvailable;

  @override
  Widget build(BuildContext context) {
    final color = isAvailable ? kCirculGreen : const Color(0xFFE5484D);
    final icon = isAvailable
        ? Icons.check_circle_rounded
        : Icons.cancel_rounded;
    final text = isAvailable ? 'username available' : 'username unavailable';

    return Row(
      children: [
        Icon(icon, color: color, size: 19),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _PaleIcon extends StatelessWidget {
  const _PaleIcon({required this.icon, this.dark = false});

  final IconData icon;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 20,
      backgroundColor: dark ? const Color(0xFF206E4D) : const Color(0xFFE7F1ED),
      child: Icon(icon, color: dark ? Colors.white : kCirculGreen, size: 21),
    );
  }
}

class _LegalText extends StatelessWidget {
  const _LegalText({required this.text, this.muted = false});

  final String text;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: muted ? const Color(0xFFC1CAC5) : const Color(0xFF6C756F),
        fontSize: 12,
        height: 1.35,
      ),
    );
  }
}

OutlineInputBorder _fieldBorder({
  Color color = const Color(0xFFC6D0CB),
  double width = 1,
}) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(11),
    borderSide: BorderSide(color: color, width: width),
  );
}
