import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/api.dart';
import '../core/session.dart';
import '../core/theme.dart';
import '../widgets/brand.dart';
import '../widgets/common.dart';

/// Branded header and light authentication card shared by auth screens.
class AuthScaffold extends StatelessWidget {
  final String subtitle;
  final String title;
  final IconData icon;
  final Widget child;
  const AuthScaffold({
    super.key,
    required this.subtitle,
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Stack(children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFA74138),
                    Color(0xFF8C2F28),
                    Color(0xFF681F1D)
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: -72,
            top: 150,
            child: Icon(Icons.add_rounded,
                size: 250, color: C.opacity(Colors.white, .045)),
          ),
          Positioned(
            left: -90,
            top: 320,
            child: Icon(Icons.add_rounded,
                size: 220, color: C.opacity(Colors.white, .04)),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.topCenter,
                        children: [
                          const Align(
                            alignment: Alignment.topLeft,
                            child: RoundBack(),
                          ),
                          const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: BrandLockup(
                              logoSize: 112,
                              connectColor: Color(0xFFE2C35B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Donate Blood. Save Lives',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'P R C  -  K A L I N G A  C H A P T E R',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFFE2C35B),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 28),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFEF8),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: C.opacity(Colors.black, .18),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: C.maroon,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child:
                                      Icon(icon, color: Colors.white, size: 23),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    title,
                                    style: const TextStyle(
                                      color: Color(0xFF292535),
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            child,
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

Widget _switchLink(String text, String action, VoidCallback onTap) => Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('$text ',
                style: const TextStyle(color: C.muted, fontSize: 13)),
            GestureDetector(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(action,
                    style: const TextStyle(
                        color: C.maroon,
                        fontWeight: FontWeight.w800,
                        fontSize: 13)),
              ),
            ),
          ]),
    );

Widget _googleButton(
        {required VoidCallback onPressed, required bool loading}) =>
    SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: loading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF393643),
          side: const BorderSide(color: Color(0xFFE1DED8)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'G',
                    style: TextStyle(
                      color: Color(0xFF4285F4),
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(width: 10),
                  Text('Continue with Google',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
      ),
    );

Widget _authDivider() => Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Row(children: [
        const Expanded(child: Divider(color: Color(0xFFE6E2DC))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('OR',
              style: TextStyle(
                  color: C.opacity(C.muted, .8),
                  fontSize: 11,
                  letterSpacing: .5)),
        ),
        const Expanded(child: Divider(color: Color(0xFFE6E2DC))),
      ]),
    );

Widget _authSubmitButton({
  required String label,
  required bool loading,
  required VoidCallback onPressed,
}) =>
    SizedBox(
      height: 50,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: C.brandRed,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white),
              )
            : Text(label),
      ),
    );

Widget _eye(bool hidden, VoidCallback toggle) => IconButton(
      tooltip: hidden ? 'Show password' : 'Hide password',
      icon: Icon(
          hidden ? Icons.visibility_off_rounded : Icons.visibility_rounded,
          color: Colors.black),
      onPressed: toggle,
    );

// ============================================================================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with FormErrors {
  final _form = GlobalKey<FormState>();
  final _id = TextEditingController();
  final _pw = TextEditingController();
  bool _hide = true, _busy = false;

  @override
  void dispose() {
    _id.dispose();
    _pw.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_form.currentState!.validate()) return;
    final nav = Navigator.of(context);
    final state = context.read<AppState>();
    setState(() => _busy = true);
    try {
      await state.login(_id.text.trim(), _pw.text);
      nav.popUntil((r) => r.isFirst); // Gate swaps to the main app
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => applyApiError(e));
      toast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _googleSignIn() async {
    setState(() => _busy = true);
    try {
      await context.read<AppState>().loginWithGoogle();
    } on ApiException catch (e) {
      if (mounted) toast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Welcome back',
      icon: Icons.login_rounded,
      subtitle: 'Log in to your account',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _googleButton(onPressed: _googleSignIn, loading: _busy),
          _authDivider(),
          Form(
            key: _form,
            child: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const FieldLabel('Email'),
                  AppTextField(
                    hint: 'you@example.com',
                    controller: _id,
                    icon: Icons.mail_rounded,
                    style: FieldStyle.auth,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [
                      AutofillHints.username,
                      AutofillHints.email
                    ],
                    validator: V.email,
                    serverError: srv['identifier'],
                    onChanged: (_) => clearErr('identifier'),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const FieldLabel('Password'),
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: C.maroon,
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ForgotPasswordScreen(
                              initialEmail:
                                  _id.text.contains('@') ? _id.text.trim() : '',
                            ),
                          ),
                        ),
                        child: const Text('Forgot password?',
                            style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                  AppTextField(
                    hint: 'Enter your password',
                    controller: _pw,
                    icon: Icons.lock_rounded,
                    style: FieldStyle.auth,
                    obscure: _hide,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    validator: V.required('Password'),
                    serverError: srv['password'],
                    onChanged: (_) => clearErr('password'),
                    onSubmitted: (_) => _submit(),
                    suffix: _eye(
                      _hide,
                      () => setState(() => _hide = !_hide),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _authSubmitButton(
                      label: 'Log in', onPressed: _submit, loading: _busy),
                ],
              ),
            ),
          ),
          _switchLink(
            "Don't have an account?",
            'Create one',
            () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const SignupScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> with FormErrors {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pw = TextEditingController();
  bool _hide = true, _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _pw.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_form.currentState!.validate()) return;
    final nav = Navigator.of(context);
    final state = context.read<AppState>();
    setState(() => _busy = true);
    try {
      await state.signup(_name.text.trim(), _email.text.trim(), _pw.text);
      nav.popUntil((r) => r.isFirst);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => applyApiError(e));
      toast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _googleSignIn() async {
    setState(() => _busy = true);
    try {
      await context.read<AppState>().loginWithGoogle();
    } on ApiException catch (e) {
      if (mounted) toast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Create your account',
      icon: Icons.person_add_alt_1_rounded,
      subtitle: 'Join RedCross Connect+',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _googleButton(onPressed: _googleSignIn, loading: _busy),
          _authDivider(),
          Form(
            key: _form,
            child: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const FieldLabel('Full name'),
                  AppTextField(
                    hint: 'Your full name',
                    controller: _name,
                    icon: Icons.person_rounded,
                    style: FieldStyle.auth,
                    capitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.name],
                    validator: V.minLen('Full name', 2),
                    serverError: srv['fullName'],
                    onChanged: (_) => clearErr('fullName'),
                  ),
                  const SizedBox(height: 14),
                  const FieldLabel('Email'),
                  AppTextField(
                    hint: 'you@example.com',
                    controller: _email,
                    icon: Icons.mail_rounded,
                    style: FieldStyle.auth,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    validator: V.email,
                    serverError: srv['email'],
                    onChanged: (_) => clearErr('email'),
                  ),
                  const SizedBox(height: 14),
                  const FieldLabel('Password'),
                  AppTextField(
                    hint: 'Create a password',
                    controller: _pw,
                    icon: Icons.lock_rounded,
                    style: FieldStyle.auth,
                    obscure: _hide,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.newPassword],
                    validator: V.password,
                    serverError: srv['password'],
                    onChanged: (_) => clearErr('password'),
                    onSubmitted: (_) => _submit(),
                    suffix: _eye(_hide, () => setState(() => _hide = !_hide)),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 8, left: 4),
                    child: Text('8+ characters with letters and a number',
                        style: TextStyle(color: C.muted, fontSize: 11)),
                  ),
                  const SizedBox(height: 18),
                  _authSubmitButton(
                      label: 'Create account',
                      onPressed: _submit,
                      loading: _busy),
                ],
              ),
            ),
          ),
          _switchLink(
            'Already have an account?',
            'Log in',
            () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
/// Two steps: ask for the email, then the 6-digit code + a new password.
class ForgotPasswordScreen extends StatefulWidget {
  final String initialEmail;
  const ForgotPasswordScreen({super.key, this.initialEmail = ''});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with FormErrors {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _email =
      TextEditingController(text: widget.initialEmail);
  final _code = TextEditingController();
  final _pw = TextEditingController();
  bool _codeSent = false, _hide = true, _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _pw.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_form.currentState!.validate()) return;
    final api = context.read<AppState>().api;
    setState(() => _busy = true);
    try {
      if (!_codeSent) {
        final devCode = await api.forgotPassword(_email.text.trim());
        if (!mounted) return;
        setState(() => _codeSent = true);
        toast(
            context,
            devCode != null
                ? 'Dev mode: your code is $devCode'
                : 'If that email is registered, a code is on its way.');
      } else {
        await api.resetPassword(
            _email.text.trim(), _code.text.trim(), _pw.text);
        if (!mounted) return;
        toast(context, 'Password updated. Please log in.');
        Navigator.pop(context);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => applyApiError(e));
      toast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: _codeSent ? 'Enter your code' : 'Reset password',
      icon: Icons.lock_reset_rounded,
      subtitle: _codeSent
          ? 'Enter the 6-digit code we sent you'
          : 'Enter your email to reset your password',
      child: Form(
        key: _form,
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const FieldLabel('Email'),
          AppTextField(
            hint: 'you@example.com',
            controller: _email,
            icon: Icons.mail_rounded,
            style: FieldStyle.auth,
            readOnly: _codeSent,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: V.email,
            serverError: srv['email'],
            onChanged: (_) => clearErr('email'),
          ),
          if (_codeSent) ...[
            const SizedBox(height: 14),
            const FieldLabel('6-digit code'),
            AppTextField(
              hint: '6-digit code',
              controller: _code,
              icon: Icons.pin_rounded,
              style: FieldStyle.auth,
              keyboardType: TextInputType.number,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textInputAction: TextInputAction.next,
              validator: (v) => (v ?? '').trim().length == 6
                  ? null
                  : 'Enter the 6-digit code',
              serverError: srv['code'],
              onChanged: (_) => clearErr('code'),
            ),
            const SizedBox(height: 14),
            const FieldLabel('New password'),
            AppTextField(
              hint: 'New password',
              controller: _pw,
              icon: Icons.lock_rounded,
              style: FieldStyle.auth,
              obscure: _hide,
              validator: V.password,
              serverError: srv['newPassword'],
              onChanged: (_) => clearErr('newPassword'),
              onSubmitted: (_) => _submit(),
              suffix: _eye(_hide, () => setState(() => _hide = !_hide)),
            ),
          ],
          const SizedBox(height: 20),
          _authSubmitButton(
            label: _codeSent ? 'Reset password' : 'Send code',
            onPressed: _submit,
            loading: _busy,
          ),
          if (_codeSent)
            TextButton(
              style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFA8BFA6)),
              onPressed: _busy ? null : () => setState(() => _codeSent = false),
              child: const Text('Use a different email'),
            ),
        ]),
      ),
    );
  }
}
