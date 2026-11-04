import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/session.dart';
import '../core/theme.dart';
import '../widgets/brand.dart';
import '../widgets/common.dart';
import 'auth.dart';
import 'shell.dart';

/// Root widget: splash while restoring the session, then either the welcome
/// screen (logged out) or the main app (logged in).
class Gate extends StatelessWidget {
  const Gate({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    Widget child;
    if (s.booting) {
      child = const _SplashLoading(key: ValueKey('boot'));
    } else if (s.bootError != null) {
      child = _OfflineRetry(
          key: const ValueKey('offline'),
          message: s.bootError!,
          onRetry: s.init);
    } else if (s.user != null) {
      child = const MainShell(key: ValueKey('shell'));
    } else {
      child = const WelcomeScreen(key: ValueKey('welcome'));
    }
    return AnimatedSwitcher(
        duration: const Duration(milliseconds: 350), child: child);
  }
}

class _Backdrop extends StatelessWidget {
  final Widget child;
  const _Backdrop({required this.child});

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFC94343), Color(0xFFA40000), Color(0xFF6E0000)],
            ),
          ),
          child: Stack(children: [
            // soft oversized crosses as texture (stands in for the photo in the mock-up)
            Positioned(
                right: -70,
                top: 80,
                child: Icon(Icons.add_rounded,
                    size: 300, color: C.opacity(Colors.white, .05))),
            Positioned(
                left: -90,
                bottom: 40,
                child: Icon(Icons.add_rounded,
                    size: 260, color: C.opacity(Colors.white, .05))),
            SafeArea(child: child),
          ]),
        ),
      );
}

class _SplashLoading extends StatelessWidget {
  const _SplashLoading({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        body: _Backdrop(
          child: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: const [
              BrandLockup(logoSize: 150, connectColor: Colors.white),
              SizedBox(height: 32),
              SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                      strokeWidth: 3, color: Colors.white)),
            ]),
          ),
        ),
      );
}

class _OfflineRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _OfflineRetry(
      {super.key, required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) => Scaffold(
      body: _Backdrop(
          child: ErrorRetry(message: message, onRetry: onRetry, dark: true)));
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _Backdrop(
        child: TweenAnimationBuilder<double>(
          // one orchestrated entrance, as the screen opens
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
          builder: (context, t, child) => Opacity(
              opacity: t,
              child: Transform.translate(
                  offset: Offset(0, 24 * (1 - t)), child: child)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: Column(children: [
              const Spacer(flex: 3),
              const BrandLockup(logoSize: 168, connectColor: Colors.white),
              const SizedBox(height: 22),
              const Text('Donate Blood. Save Lives',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w500)),
              const Spacer(flex: 4),
              PrimaryButton(
                label: 'Get Started',
                color: const Color(0xFFFF0000),
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SignupScreen())),
              ),
              const SizedBox(height: 14),
              PrimaryButton(
                label: 'Login',
                color: C.opacity(Colors.white, .26),
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const LoginScreen())),
              ),
              const SizedBox(height: 36),
            ]),
          ),
        ),
      ),
    );
  }
}
