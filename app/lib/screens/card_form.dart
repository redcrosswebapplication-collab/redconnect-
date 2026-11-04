import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api.dart';
import '../core/models.dart';
import '../core/session.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../widgets/common.dart';
import 'card_confirmation.dart';

class CardFormScreen extends StatefulWidget {
  final CardType card;
  final List<CardType> cards;
  const CardFormScreen({super.key, required this.card, required this.cards});
  @override
  State<CardFormScreen> createState() => _CardFormScreenState();
}

class _CardFormScreenState extends State<CardFormScreen> with FormErrors {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _mobile;
  late final TextEditingController _email;
  final _dobText = TextEditingController();
  DateTime? _dob;
  late String _code = widget.card.code;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final u = context.read<AppState>().user!;
    _name = TextEditingController(text: u.fullName);
    _mobile = TextEditingController(text: u.phone ?? '');
    _email = TextEditingController(text: u.email);
  }

  @override
  void dispose() {
    _name.dispose();
    _mobile.dispose();
    _email.dispose();
    _dobText.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 20, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Date of birth',
    );
    if (d != null) {
      setState(() {
        _dob = d;
        _dobText.text = fmtDate(d);
        srv.remove('birthDate');
      });
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_form.currentState!.validate()) return;
    final api = context.read<AppState>().api;
    final nav = Navigator.of(context);
    setState(() => _busy = true);
    try {
      final req = await api.createCardRequest({
        'fullName': _name.text.trim(),
        'birthDate': ymd(_dob!),
        'cardCode': _code,
        'mobile': _mobile.text.trim(),
        'email': _email.text.trim().isEmpty ? null : _email.text.trim(),
      });
      nav.pushReplacement(MaterialPageRoute(
          builder: (_) => CardConfirmationScreen(request: req)));
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: redAppBar(context, 'GET MY CARD FORM'),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
          child: Form(
            key: _form,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('FILL THE FORM FOR YOUR CARD',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Colors.black)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(color: Colors.black)),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Member details',
                              style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: C.ink)),
                          const Text('Use your name as it appears on your ID.',
                              style: TextStyle(fontSize: 12.5, color: C.muted)),
                          const SizedBox(height: 14),
                          const FieldLabel('Full name'),
                          AppTextField(
                            hint: 'Enter your full name',
                            controller: _name,
                            style: FieldStyle.outlined,
                            capitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            validator: V.minLen('Full name', 2),
                            serverError: srv['fullName'],
                            onChanged: (_) => clearErr('fullName'),
                          ),
                          const SizedBox(height: 12),
                          Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const FieldLabel('Date of birth'),
                                        AppTextField(
                                          hint: 'DD / MM / YYYY',
                                          controller: _dobText,
                                          style: FieldStyle.outlined,
                                          readOnly: true,
                                          onTap: _pickDob,
                                          suffix: const Icon(
                                              Icons.calendar_month_rounded,
                                              size: 20,
                                              color: C.ink),
                                          validator: (_) =>
                                              _dob == null ? 'Required' : null,
                                          serverError: srv['birthDate'],
                                        ),
                                      ]),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const FieldLabel('Card type'),
                                        DropdownButtonFormField<String>(
                                          // Keep the pre-3.33 argument for the Flutter 3.22 minimum.
                                          // ignore: deprecated_member_use
                                          value: _code,
                                          isExpanded: true,
                                          icon: const Icon(Icons
                                              .keyboard_arrow_down_rounded),
                                          style: const TextStyle(
                                              color: C.ink,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14),
                                          decoration: InputDecoration(
                                            filled: true,
                                            fillColor: const Color(0xFFE4DADA),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 14,
                                                    vertical: 15),
                                            border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                                borderSide: const BorderSide(
                                                    color: Colors.black)),
                                            enabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                                borderSide: const BorderSide(
                                                    color: Colors.black)),
                                          ),
                                          items: [
                                            for (final c in widget.cards)
                                              DropdownMenuItem(
                                                  value: c.code,
                                                  child: Text(
                                                      '${c.name} · ${peso(c.price)}',
                                                      overflow: TextOverflow
                                                          .ellipsis)),
                                          ],
                                          onChanged: (v) => setState(
                                              () => _code = v ?? _code),
                                        ),
                                      ]),
                                ),
                              ]),
                          const SizedBox(height: 12),
                          const FieldLabel('Mobile number'),
                          AppTextField(
                            hint: 'Enter your mobile number',
                            controller: _mobile,
                            style: FieldStyle.outlined,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            validator: V.phone(),
                            serverError: srv['mobile'],
                            onChanged: (_) => clearErr('mobile'),
                          ),
                          const SizedBox(height: 12),
                          const FieldLabel('Email address', hint: '(optional)'),
                          AppTextField(
                            hint: 'Enter your email address',
                            controller: _email,
                            style: FieldStyle.outlined,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.done,
                            validator: V.emailOptional(),
                            serverError: srv['email'],
                            onChanged: (_) => clearErr('email'),
                            onSubmitted: (_) => _submit(),
                          ),
                        ]),
                  ),
                  const SizedBox(height: 26),
                  PrimaryButton(
                      label: 'SUBMIT',
                      trailing: Icons.arrow_forward_rounded,
                      onPressed: _submit,
                      loading: _busy),
                ]),
          ),
        ),
      ),
    );
  }
}
