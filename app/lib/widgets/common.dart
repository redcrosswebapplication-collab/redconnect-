import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/api.dart';
import '../core/theme.dart';
import '../core/utils.dart';

// ----------------------------------------------------------------------------
// Feedback
// ----------------------------------------------------------------------------
void toast(BuildContext context, String message, {bool error = false}) {
  final m = ScaffoldMessenger.of(context);
  m.hideCurrentSnackBar();
  m.showSnackBar(SnackBar(
    content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
    backgroundColor: error ? const Color(0xFFB3261E) : const Color(0xFF2B2B2B),
    duration: Duration(seconds: error ? 4 : 3),
  ));
}

Future<bool> confirm(BuildContext context,
    {required String title,
    required String message,
    String yes = 'Yes',
    String no = 'Cancel'}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: Text(no)),
        FilledButton(
            style: FilledButton.styleFrom(backgroundColor: C.deepRed),
            onPressed: () => Navigator.pop(c, true),
            child: Text(yes)),
      ],
    ),
  );
  return r ?? false;
}

// ----------------------------------------------------------------------------
// Validators
// ----------------------------------------------------------------------------
class V {
  static String? Function(String?) required(String label) =>
      (v) => (v == null || v.trim().isEmpty) ? '$label is required' : null;

  static String? Function(String?) minLen(String label, int n) => (v) {
        final t = (v ?? '').trim();
        if (t.isEmpty) return '$label is required';
        return t.length < n ? '$label must be at least $n characters' : null;
      };

  static String? email(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return 'Email is required';
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$').hasMatch(t)
        ? null
        : 'Enter a valid email address';
  }

  static String? Function(String?) emailOptional() =>
      (v) => (v ?? '').trim().isEmpty ? null : email(v);

  static String? Function(String?) phone({String label = 'Mobile number'}) =>
      (v) {
        final t = (v ?? '').replaceAll(RegExp(r'[\s-]'), '');
        if (t.isEmpty) return '$label is required';
        return RegExp(r'^(\+?63|0)9\d{9}$').hasMatch(t)
            ? null
            : 'Use a PH mobile number, e.g. 09171234567';
      };

  static String? password(String? v) {
    final t = v ?? '';
    if (t.length < 8) return 'At least 8 characters';
    if (!RegExp(r'[A-Za-z]').hasMatch(t) || !RegExp(r'\d').hasMatch(t)) {
      return 'Use letters and at least one number';
    }
    return null;
  }
}

/// Lets a State hold server-side field errors (422 responses) next to client validation.
mixin FormErrors<T extends StatefulWidget> on State<T> {
  final Map<String, String> srv = {};
  void clearErr(String key) {
    if (srv.containsKey(key)) setState(() => srv.remove(key));
  }

  void applyApiError(ApiException e) {
    srv
      ..clear()
      ..addAll(e.fields);
  }
}

// ----------------------------------------------------------------------------
// Inputs
// ----------------------------------------------------------------------------
enum FieldStyle { pill, form, outlined, glass, auth }

class AppTextField extends StatelessWidget {
  final String hint;
  final TextEditingController? controller;
  final IconData? icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final String? serverError;
  final ValueChanged<String>? onChanged;
  final FieldStyle style;
  final bool readOnly;
  final VoidCallback? onTap;
  final Widget? suffix;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final int maxLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onSubmitted;
  final TextCapitalization capitalization;

  const AppTextField({
    super.key,
    required this.hint,
    this.controller,
    this.icon,
    this.obscure = false,
    this.keyboardType,
    this.validator,
    this.serverError,
    this.onChanged,
    this.style = FieldStyle.form,
    this.readOnly = false,
    this.onTap,
    this.suffix,
    this.textInputAction,
    this.autofillHints,
    this.maxLines = 1,
    this.maxLength,
    this.inputFormatters,
    this.onSubmitted,
    this.capitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    late Color fill, hintColor, textColor, errorColor;
    late double radius;
    BorderSide border = BorderSide.none;
    switch (style) {
      case FieldStyle.pill:
        fill = C.field;
        hintColor = const Color(0xFF6B6B6B);
        textColor = Colors.black;
        errorColor = const Color(0xFFFFB4AB);
        radius = 30;
        break;
      case FieldStyle.form:
        fill = C.soft;
        hintColor = const Color(0xFF8A8484);
        textColor = C.ink;
        errorColor = const Color(0xFFB3261E);
        radius = 16;
        break;
      case FieldStyle.outlined:
        fill = const Color(0xFFE4DADA);
        hintColor = const Color(0xFF8A7E7E);
        textColor = C.ink;
        errorColor = const Color(0xFFB3261E);
        radius = 14;
        border = const BorderSide(color: Colors.black, width: 1);
        break;
      case FieldStyle.glass:
        fill = const Color(0x26FFFFFF);
        hintColor = Colors.white70;
        textColor = Colors.white;
        errorColor = const Color(0xFFFFD6D1);
        radius = 18;
        border = const BorderSide(color: Colors.black, width: 1);
        break;
      case FieldStyle.auth:
        fill = Colors.white;
        hintColor = const Color(0xFF96919A);
        textColor = C.ink;
        errorColor = const Color(0xFFB3261E);
        radius = 12;
        border = const BorderSide(color: Color(0xFFE1DED8));
        break;
    }
    OutlineInputBorder ob(BorderSide s) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius), borderSide: s);

    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      maxLines: obscure ? 1 : maxLines,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      textCapitalization: capitalization,
      onFieldSubmitted: onSubmitted,
      forceErrorText: serverError,
      validator: validator,
      onChanged: onChanged,
      style: TextStyle(
          color: textColor, fontWeight: FontWeight.w700, fontSize: 15),
      cursorColor: textColor,
      decoration: InputDecoration(
        hintText: hint,
        counterText: '',
        hintStyle: TextStyle(color: hintColor, fontWeight: FontWeight.w700),
        prefixIcon: icon == null
            ? null
            : Icon(icon,
                color: style == FieldStyle.pill ? Colors.black : hintColor,
                size: 22),
        suffixIcon: suffix,
        filled: true,
        fillColor: fill,
        contentPadding: EdgeInsets.symmetric(
            horizontal: style == FieldStyle.auth ? 16 : 20,
            vertical: style == FieldStyle.pill ? 18 : 16),
        errorStyle: TextStyle(color: errorColor, fontWeight: FontWeight.w600),
        errorMaxLines: 2,
        border: ob(border),
        enabledBorder: ob(border),
        focusedBorder: ob(style == FieldStyle.pill
            ? const BorderSide(color: Colors.white, width: 2)
            : BorderSide(
                color: style == FieldStyle.glass
                    ? Colors.white
                    : style == FieldStyle.auth
                        ? C.maroon
                        : C.deepRed,
                width: 1.6)),
        errorBorder: ob(BorderSide(color: errorColor, width: 1.4)),
        focusedErrorBorder: ob(BorderSide(color: errorColor, width: 1.8)),
      ),
    );
  }
}

/// Label above a field (used on white cards).
class FieldLabel extends StatelessWidget {
  final String text;
  final String? hint;
  const FieldLabel(this.text, {super.key, this.hint});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6, top: 2),
        child: Text.rich(TextSpan(children: [
          TextSpan(
              text: text,
              style: const TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 13.5, color: C.ink)),
          if (hint != null)
            TextSpan(
                text: '  $hint',
                style: const TextStyle(fontSize: 11, color: C.muted)),
        ])),
      );
}

// ----------------------------------------------------------------------------
// Buttons / chrome
// ----------------------------------------------------------------------------
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final Color color;
  final Color foreground;
  final IconData? trailing;
  final BorderSide border;
  final double height;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.color = C.wine,
    this.foreground = Colors.white,
    this.trailing,
    this.border = BorderSide.none,
    this.height = 58,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: height,
        child: FilledButton(
          onPressed: loading ? null : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: color,
            foregroundColor: foreground,
            disabledBackgroundColor: C.opacity(color, .75),
            disabledForegroundColor: foreground,
            shape: StadiumBorder(side: border),
            textStyle: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: .6),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: loading
                ? SizedBox(
                    key: const ValueKey('l'),
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        strokeWidth: 3, color: foreground))
                : Row(
                    key: const ValueKey('t'),
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                        Flexible(
                            child:
                                Text(label, overflow: TextOverflow.ellipsis)),
                        if (trailing != null) ...[
                          const SizedBox(width: 8),
                          Icon(trailing, size: 20)
                        ],
                      ]),
          ),
        ),
      );
}

/// Round translucent back button from the design.
class RoundBack extends StatelessWidget {
  final Color color;
  const RoundBack({super.key, this.color = Colors.white});
  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: 'Back',
        style: IconButton.styleFrom(backgroundColor: C.opacity(color, .22)),
        icon: Icon(Icons.arrow_back_rounded, color: color, size: 20),
        onPressed: () => Navigator.maybePop(context),
      );
}

PreferredSizeWidget redAppBar(BuildContext context, String title,
    {Color color = C.maroon,
    bool back = true,
    VoidCallback? onMenu,
    List<Widget>? actions,
    PreferredSizeWidget? bottom}) {
  return AppBar(
    backgroundColor: color,
    title: Text(title),
    automaticallyImplyLeading: false,
    leading: back
        ? IconButton(
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => Navigator.maybePop(context))
        : (onMenu != null
            ? IconButton(
                tooltip: 'Menu',
                icon: const Icon(Icons.menu_rounded),
                onPressed: onMenu)
            : null),
    actions: actions,
    bottom: bottom,
  );
}

class WhiteCard extends StatelessWidget {
  final Widget child;
  final String? title;
  final EdgeInsets padding;
  const WhiteCard(
      {super.key,
      required this.child,
      this.title,
      this.padding = const EdgeInsets.fromLTRB(18, 18, 18, 20)});
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(26)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (title != null) ...[
            Text(title!,
                style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: Colors.black)),
            const SizedBox(height: 14),
          ],
          child,
        ]),
      );
}

class StatusChip extends StatelessWidget {
  final String status;
  const StatusChip(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    Color bg, fg;
    switch (status) {
      case 'approved':
      case 'confirmed':
      case 'fulfilled':
      case 'issued':
      case 'completed':
        bg = const Color(0xFFE2F3E2);
        fg = const Color(0xFF1B6B24);
        break;
      case 'rejected':
      case 'cancelled':
        bg = const Color(0xFFF6DEDC);
        fg = const Color(0xFFA32A22);
        break;
      default: // pending, awaiting_review, open
        bg = const Color(0xFFFBEFD5);
        fg = const Color(0xFF8A5A00);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(prettyStatus(status),
          style:
              TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w800)),
    );
  }
}

class LoadingView extends StatelessWidget {
  final Color color;
  const LoadingView({super.key, this.color = C.deepRed});
  @override
  Widget build(BuildContext context) =>
      Center(child: CircularProgressIndicator(color: color));
}

class ErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final bool dark;
  const ErrorRetry(
      {super.key,
      required this.message,
      required this.onRetry,
      this.dark = false});
  @override
  Widget build(BuildContext context) {
    final fg = dark ? Colors.white : C.ink;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.cloud_off_rounded, size: 46, color: C.opacity(fg, .7)),
          const SizedBox(height: 12),
          Text(message,
              textAlign: TextAlign.center,
              style: TextStyle(color: fg, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          FilledButton.icon(
            style: FilledButton.styleFrom(
                backgroundColor: dark ? Colors.white : C.deepRed,
                foregroundColor: dark ? C.deepRed : Colors.white),
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
          ),
        ]),
      ),
    );
  }
}

class EmptyView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  const EmptyView(
      {super.key,
      required this.icon,
      required this.title,
      required this.message});
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 54, color: C.opacity(C.muted, .6)),
            const SizedBox(height: 12),
            Text(title,
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w800, color: C.ink)),
            const SizedBox(height: 6),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: C.muted)),
          ]),
        ),
      );
}

/// Runs [fn] while disabling double taps; shows server errors as toasts.
Future<T?> guard<T>(BuildContext context, Future<T> Function() fn) async {
  try {
    return await fn();
  } on ApiException catch (e) {
    if (context.mounted) toast(context, e.message, error: true);
    return null;
  }
}
