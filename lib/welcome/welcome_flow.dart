import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../shared/circul_header.dart';

enum WelcomeAuthProvider { google, apple }

enum WelcomeAuthOutcome { existingAccount, needsAccount }

abstract class WelcomeAuthService {
  Future<WelcomeAuthOutcome> continueWithProvider(WelcomeAuthProvider provider);
}

class PlaceholderWelcomeAuthService implements WelcomeAuthService {
  const PlaceholderWelcomeAuthService();

  @override
  Future<WelcomeAuthOutcome> continueWithProvider(
    WelcomeAuthProvider provider,
  ) async {
    return WelcomeAuthOutcome.existingAccount;
  }
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
  final _history = <_WelcomeStep>[];

  void _go(_WelcomeStep step) {
    setState(() {
      _transitionDirection = 1;
      _history.add(_step);
      _step = step;
    });
  }

  void _back() {
    if (_history.isEmpty) return;
    setState(() {
      _transitionDirection = -1;
      _step = _history.removeLast();
    });
  }

  Future<void> _continueWithProvider(WelcomeAuthProvider provider) async {
    final outcome = await widget.authService.continueWithProvider(provider);
    if (!mounted) return;

    if (outcome == WelcomeAuthOutcome.existingAccount) {
      widget.onComplete();
    } else {
      _go(_WelcomeStep.createAccount);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screen = switch (_step) {
      _WelcomeStep.welcome => _WelcomeScreen(
        onStart: () => _go(_WelcomeStep.loginMethod),
      ),
      _WelcomeStep.loginMethod => _LoginMethodScreen(
        onEmail: () => _go(_WelcomeStep.createAccount),
        onGoogle: () => _continueWithProvider(WelcomeAuthProvider.google),
        onApple: () => _continueWithProvider(WelcomeAuthProvider.apple),
        onCreateAccount: () => _go(_WelcomeStep.createAccount),
      ),
      _WelcomeStep.createAccount => _CreateAccountScreen(
        onBack: _back,
        onCreateAccount: () => _go(_WelcomeStep.verifyMethod),
        onLogin: () => _go(_WelcomeStep.loginMethod),
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
        onVerify: () => _go(_WelcomeStep.createPassword),
      ),
      _WelcomeStep.whatsappVerification => _OtpVerificationScreen.whatsapp(
        onBack: _back,
        onVerify: () => _go(_WelcomeStep.createPassword),
      ),
      _WelcomeStep.createPassword => _CreatePasswordScreen(
        onBack: _back,
        onCreateAccount: () => _go(_WelcomeStep.username),
      ),
      _WelcomeStep.username => _UsernameScreen(
        onBack: _back,
        onContinue: widget.onComplete,
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
  createAccount,
  verifyMethod,
  phoneNumber,
  emailVerification,
  whatsappVerification,
  createPassword,
  username,
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
  });

  final VoidCallback onEmail;
  final VoidCallback onGoogle;
  final VoidCallback onApple;
  final VoidCallback onCreateAccount;

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
    required this.onCreateAccount,
    required this.onLogin,
  });

  final VoidCallback onBack;
  final VoidCallback onCreateAccount;
  final VoidCallback onLogin;

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
            const _WelcomeField(
              label: 'Email Address',
              hint: 'name@example.com',
              icon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 22),
            const _WelcomeField(
              label: 'Full Name',
              hint: 'Jane Doe',
              icon: Icons.person_outline_rounded,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 22),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Date of Birth',
                style: TextStyle(
                  color: Color(0xFF4B5550),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: const [
                Expanded(child: _DateBox(label: 'DD')),
                SizedBox(width: 12),
                Expanded(child: _DateBox(label: 'MM')),
                SizedBox(width: 12),
                Expanded(child: _DateBox(label: 'YYYY')),
              ],
            ),
          ],
        ),
      ),
      bottom: Column(
        children: [
          _WelcomePrimaryButton(
            label: 'Create Account',
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

class _OtpVerificationScreen extends StatelessWidget {
  const _OtpVerificationScreen.email({
    required this.onBack,
    required this.onVerify,
  }) : isWhatsapp = false;

  const _OtpVerificationScreen.whatsapp({
    required this.onBack,
    required this.onVerify,
  }) : isWhatsapp = true;

  final bool isWhatsapp;
  final VoidCallback onBack;
  final VoidCallback onVerify;

  @override
  Widget build(BuildContext context) {
    final title = isWhatsapp ? 'Verify your phone' : 'Verify your email';
    final subtitle = isWhatsapp
        ? "We've sent a 6-digit verification code to\n+62 8000-0000 via WhatsApp."
        : "We've sent a 6-digit verification code to\nhello@example.com. Please enter it below to\ncontinue.";

    return _WelcomeScaffold(
      header: isWhatsapp
          ? _BackHeader(onBack: onBack)
          : _BackLogoHeader(onBack: onBack),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: isWhatsapp ? 58 : 70),
            _ScreenTitle(title: title, subtitle: subtitle),
            const SizedBox(height: 32),
            const _OtpBoxes(),
            const SizedBox(height: 28),
            Center(
              child: Text(
                isWhatsapp
                    ? "Didn't receive the code? Resend code"
                    : "Didn't receive the code?",
                style: TextStyle(
                  color: isWhatsapp ? kCirculGreen : const Color(0xFF3F4944),
                  fontSize: 15,
                ),
              ),
            ),
            if (!isWhatsapp) ...[
              const SizedBox(height: 18),
              const Center(
                child: Text(
                  'C Resend code',
                  style: TextStyle(
                    color: kCirculGreen,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      bottom: Column(
        children: [
          _WelcomePrimaryButton(
            label: isWhatsapp ? 'Verify Code' : 'Verify',
            icon: isWhatsapp
                ? Icons.check_circle_outline_rounded
                : Icons.arrow_forward_rounded,
            onPressed: onVerify,
            backgroundColor: isWhatsapp
                ? kCirculGreen
                : const Color(0xFF8AAE9F),
          ),
          if (isWhatsapp) ...[
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
    required this.onCreateAccount,
  });

  final VoidCallback onBack;
  final VoidCallback onCreateAccount;

  @override
  Widget build(BuildContext context) {
    return _WelcomeScaffold(
      header: _BackHeader(onBack: onBack),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            SizedBox(height: 42),
            _ScreenTitle(
              title: 'Create a password',
              subtitle: 'Set a secure password for your account.',
            ),
            SizedBox(height: 30),
            _PasswordField(),
            SizedBox(height: 18),
            _PasswordStrength(),
            SizedBox(height: 28),
            _RequirementCard(),
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

class _UsernameScreen extends StatelessWidget {
  const _UsernameScreen({required this.onBack, required this.onContinue});

  final VoidCallback onBack;
  final VoidCallback onContinue;

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
              title: 'Choose your username',
              subtitle: 'This is how your friends will find you on Circul.',
            ),
            SizedBox(height: 36),
            _PlainInput(hint: '@ username'),
            SizedBox(height: 14),
            Row(
              children: [
                Icon(Icons.new_releases_outlined, color: Color(0xFFFF3857)),
                SizedBox(width: 8),
                Text(
                  'Username Already Exist',
                  style: TextStyle(
                    color: Color(0xFFFF3857),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            _UsernameSuggestions(),
          ],
        ),
      ),
      bottom: _WelcomePrimaryButton(label: 'Continue', onPressed: onContinue),
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

class _WelcomePrimaryButton extends StatelessWidget {
  const _WelcomePrimaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.backgroundColor = kCirculGreen,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: backgroundColor,
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
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
  });

  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
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
        TextField(
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
        ),
      ],
    );
  }
}

class _PlainInput extends StatelessWidget {
  const _PlainInput({required this.hint});

  final String hint;

  @override
  Widget build(BuildContext context) {
    return TextField(
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

class _DateBox extends StatelessWidget {
  const _DateBox({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: TextField(
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          hintText: label,
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
  const _PasswordField();

  @override
  Widget build(BuildContext context) {
    return const _PasswordTextField();
  }
}

class _PasswordTextField extends StatelessWidget {
  const _PasswordTextField();

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      obscureText: false,
      initialValue: 'Circul2024!',
      decoration: InputDecoration(
        suffixIcon: const Icon(Icons.visibility_outlined),
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

class _PasswordStrength extends StatelessWidget {
  const _PasswordStrength();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: const [
            Text(
              'STRONG',
              style: TextStyle(
                color: kCirculGreen,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
            Spacer(),
            Text(
              '90% Secure',
              style: TextStyle(color: Color(0xFF3F4944), fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: const LinearProgressIndicator(
            value: .9,
            minHeight: 6,
            backgroundColor: Color(0xFFE1E5E3),
            color: kCirculGreen,
          ),
        ),
      ],
    );
  }
}

class _RequirementCard extends StatelessWidget {
  const _RequirementCard();

  @override
  Widget build(BuildContext context) {
    const items = [
      'Minimum 8 characters',
      'At least one lowercase letter',
      'At least one uppercase letter',
      'At least one numeric digit',
      'Special characters (Bonus)',
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
            Row(
              children: [
                Icon(
                  item.startsWith('Special')
                      ? Icons.stars_outlined
                      : Icons.check_circle_rounded,
                  color: kCirculGreen,
                  size: 19,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    item,
                    style: TextStyle(
                      color: item.startsWith('Special') ? kCirculGreen : kInk,
                      fontSize: 14,
                      fontWeight: item.startsWith('Special')
                          ? FontWeight.w800
                          : null,
                    ),
                  ),
                ),
              ],
            ),
            if (item != items.last) const SizedBox(height: 16),
          ],
        ],
      ),
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
  const _UsernameSuggestions();

  @override
  Widget build(BuildContext context) {
    const suggestions = ['haxsa08', 'haxsaa', 'haxsa20', 'haxsaaa'];

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
            'Pick Our Recomendation',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 18),
          for (final suggestion in suggestions) ...[
            Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: kCirculGreen,
                  size: 19,
                ),
                const SizedBox(width: 14),
                Text(suggestion, style: const TextStyle(fontSize: 14)),
              ],
            ),
            if (suggestion != suggestions.last) const SizedBox(height: 16),
          ],
        ],
      ),
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
