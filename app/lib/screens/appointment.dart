import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api.dart';
import '../core/models.dart';
import '../core/session.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../widgets/brand.dart';
import '../widgets/common.dart';
import '../widgets/tiles.dart';
import 'my_requests.dart';

// ============================================================================
/// Tab: intro ("Book Appointment Easily") + the user's upcoming appointments.
class AppointmentTab extends StatefulWidget {
  final VoidCallback onMenu;
  const AppointmentTab({super.key, required this.onMenu});
  @override
  State<AppointmentTab> createState() => _AppointmentTabState();
}

class _AppointmentTabState extends State<AppointmentTab> {
  late Future<List<Appointment>> _list;

  @override
  void initState() {
    super.initState();
    _list = context.read<AppState>().api.appointments();
  }

  Future<void> _reload() async {
    final f = context.read<AppState>().api.appointments();
    setState(() {
      _list = f;
    });
    try {
      await f;
    } catch (_) {}
  }

  Future<void> _book() async {
    final ok = await Navigator.push<bool>(context,
        MaterialPageRoute(builder: (_) => const AppointmentFormScreen()));
    if (ok == true && mounted) _reload();
  }

  Future<void> _cancel(Appointment a) async {
    final api = context.read<AppState>().api;
    final yes = await confirm(context,
        title: 'Cancel appointment?',
        message:
            '${fmtDay(a.date)} at ${fmtTime(a.time)} will be released for other donors.',
        yes: 'Cancel it',
        no: 'Keep it');
    if (!yes || !mounted) return;
    final done = await guard(
        context, () => api.cancelAppointment(a.id).then((_) => true));
    if (done == true && mounted) {
      toast(context, 'Appointment cancelled');
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar:
          redAppBar(context, 'APPOINTMENT', back: false, onMenu: widget.onMenu),
      body: RefreshIndicator(
        color: C.maroon,
        onRefresh: _reload,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 28),
          children: [
            Center(
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                    color: const Color(0xFFD0EAF5),
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: const Color(0xFFD25353), width: 7)),
                child: const Icon(Icons.calendar_month_rounded,
                    size: 78, color: Color(0xFFB01212)),
              ),
            ),
            const SizedBox(height: 22),
            const FittedBox(
                fit: BoxFit.scaleDown,
                child: Text('Book Appointment Easily',
                    style: TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                        color: Colors.black))),
            const SizedBox(height: 10),
            const Text(
                'Check availability and book your appointment in seconds, no calls needed.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF777070),
                    height: 1.35)),
            const SizedBox(height: 24),
            PrimaryButton(
                label: 'Get Started',
                onPressed: _book,
                color: C.deepRed,
                height: 62),
            const SizedBox(height: 30),
            Row(children: [
              const Expanded(
                  child: Text('Your appointments',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.black))),
              TextButton(
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              const MyRequestsScreen(initialTab: 0))),
                  child: const Text('See all',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, color: C.maroon))),
            ]),
            const SizedBox(height: 6),
            FutureBuilder<List<Appointment>>(
              future: _list,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Padding(
                      padding: EdgeInsets.all(24), child: LoadingView());
                }
                if (snap.hasError) {
                  final m = snap.error is ApiException
                      ? (snap.error as ApiException).message
                      : 'Could not load appointments.';
                  return Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(children: [
                        Expanded(
                            child: Text(m,
                                style: const TextStyle(color: C.muted))),
                        TextButton(
                            onPressed: _reload, child: const Text('Retry'))
                      ]));
                }
                final today = ymd(DateTime.now());
                final upcoming = snap.data!
                    .where((a) => a.cancellable && a.date.compareTo(today) >= 0)
                    .toList()
                    .reversed
                    .toList();
                if (upcoming.isEmpty) {
                  return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Text('No upcoming appointments yet.',
                          style: TextStyle(
                              color: C.muted, fontWeight: FontWeight.w600)));
                }
                return Column(children: [
                  for (final a in upcoming)
                    AppointmentTile(a, onCancel: () => _cancel(a))
                ]);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
class AppointmentFormScreen extends StatefulWidget {
  const AppointmentFormScreen({super.key});
  @override
  State<AppointmentFormScreen> createState() => _AppointmentFormScreenState();
}

class _AppointmentFormScreenState extends State<AppointmentFormScreen>
    with FormErrors {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  final _dateText = TextEditingController();
  DateTime? _date;
  List<Slot>? _slots;
  bool _loadingSlots = false;
  String? _slotsError;
  String? _time;
  bool _timeErr = false, _busy = false;

  @override
  void initState() {
    super.initState();
    final u = context.read<AppState>().user!;
    _name = TextEditingController(text: u.fullName);
    _phone = TextEditingController(text: u.phone ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _dateText.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    var first = DateTime(now.year, now.month, now.day);
    if (first.weekday == DateTime.sunday) {
      first = first.add(const Duration(days: 1));
    }
    final d = await showDatePicker(
      context: context,
      initialDate: (_date != null && _date!.isAfter(first)) ? _date! : first,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: first.add(const Duration(days: 60)),
      helpText: 'Preferred date (closed Sundays)',
      selectableDayPredicate: (day) => day.weekday != DateTime.sunday,
    );
    if (d == null) return;
    setState(() {
      _date = d;
      _dateText.text = fmtDay(ymd(d));
      _time = null;
      srv.remove('date');
    });
    _loadSlots();
  }

  Future<void> _loadSlots() async {
    final d = _date;
    if (d == null) return;
    final api = context.read<AppState>().api;
    setState(() {
      _loadingSlots = true;
      _slotsError = null;
    });
    try {
      final slots = await api.availability(ymd(d));
      if (!mounted || _date != d) return;
      setState(() => _slots = slots);
    } on ApiException catch (e) {
      if (mounted) setState(() => _slotsError = e.message);
    } finally {
      if (mounted) setState(() => _loadingSlots = false);
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final valid = _form.currentState!.validate();
    if (_time == null) setState(() => _timeErr = true);
    if (!valid || _time == null) return;
    final api = context.read<AppState>().api;
    final nav = Navigator.of(context);
    setState(() => _busy = true);
    try {
      final a = await api.bookAppointment(
          fullName: _name.text.trim(),
          phone: _phone.text.trim(),
          date: ymd(_date!),
          time: _time!);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (c) => AlertDialog(
          icon: const Icon(Icons.event_available_rounded,
              color: Color(0xFF2E7D32), size: 52),
          title: const Text('Appointment booked',
              style: TextStyle(fontWeight: FontWeight.w800)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(fmtDay(a.date),
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            Text(fmtTime(a.time),
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: C.deepRed)),
            const SizedBox(height: 10),
            const Text(
                "We'll confirm it shortly. You can track or cancel it from the Appointment tab.",
                textAlign: TextAlign.center),
          ]),
          actions: [
            FilledButton(
                style: FilledButton.styleFrom(backgroundColor: C.deepRed),
                onPressed: () => Navigator.pop(c),
                child: const Text('Done'))
          ],
        ),
      );
      nav.pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => applyApiError(e));
      toast(context, e.message, error: true);
      if (e.fields.containsKey('time')) {
        setState(() => _time = null);
        _loadSlots();
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _slotArea() {
    if (_date == null) {
      return const Text('Choose a date to see available times.',
          style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600));
    }
    if (_loadingSlots) {
      return const Padding(
          padding: EdgeInsets.all(12),
          child: Center(child: CircularProgressIndicator(color: Colors.white)));
    }
    if (_slotsError != null) {
      return Row(children: [
        Expanded(
            child: Text(_slotsError!,
                style: const TextStyle(color: Colors.white))),
        TextButton(
            onPressed: _loadSlots,
            child: const Text('Retry',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w800))),
      ]);
    }
    final slots = _slots ?? const <Slot>[];
    if (slots.isEmpty) {
      return const Text('No slots left on this day. Please pick another date.',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700));
    }
    return Wrap(spacing: 8, runSpacing: 8, children: [
      for (final s in slots)
        ChoiceChip(
          selected: _time == s.time,
          onSelected: s.remaining == 0
              ? null
              : (_) => setState(() {
                    _time = s.time;
                    _timeErr = false;
                    srv.remove('time');
                  }),
          showCheckmark: false,
          selectedColor: Colors.white,
          backgroundColor: C.opacity(Colors.white, .16),
          disabledColor: C.opacity(Colors.black, .18),
          side: const BorderSide(color: Colors.black),
          label: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(fmtTime(s.time),
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: _time == s.time
                        ? C.deepRed
                        : (s.remaining == 0 ? Colors.white38 : Colors.white))),
            Text(s.remaining == 0 ? 'Full' : '${s.remaining} left',
                style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: _time == s.time ? C.muted : Colors.white70)),
          ]),
        ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          child: Form(
            key: _form,
            child: Column(children: [
              Align(
                  alignment: Alignment.centerLeft,
                  child: const RoundBack(color: C.maroon)),
              const AppLogo(size: 96),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
                decoration: BoxDecoration(
                    color: C.formCard, borderRadius: BorderRadius.circular(28)),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                          'Please fill out the form below to make an appointment',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              height: 1.3)),
                      const SizedBox(height: 18),
                      AppTextField(
                          hint: 'Full Name',
                          controller: _name,
                          style: FieldStyle.glass,
                          capitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          validator: V.minLen('Full name', 2),
                          serverError: srv['fullName'],
                          onChanged: (_) => clearErr('fullName')),
                      const SizedBox(height: 12),
                      AppTextField(
                          hint: 'Phone Number',
                          controller: _phone,
                          style: FieldStyle.glass,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          validator: V.phone(label: 'Phone number'),
                          serverError: srv['phone'],
                          onChanged: (_) => clearErr('phone')),
                      const SizedBox(height: 12),
                      AppTextField(
                        hint: 'Preferred Date',
                        controller: _dateText,
                        style: FieldStyle.glass,
                        readOnly: true,
                        onTap: _pickDate,
                        suffix: const Icon(Icons.calendar_month_rounded,
                            color: Colors.white),
                        validator: (_) => _date == null ? 'Pick a date' : null,
                        serverError: srv['date'],
                      ),
                      const SizedBox(height: 18),
                      const Text('Preferred Time',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 15)),
                      const SizedBox(height: 8),
                      _slotArea(),
                      if (_timeErr || srv['time'] != null)
                        Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(srv['time'] ?? 'Pick a time',
                                style: const TextStyle(
                                    color: Color(0xFFFFD6D1),
                                    fontWeight: FontWeight.w700))),
                      const SizedBox(height: 22),
                      const Text(
                          'By clicking Book Appointment, you agree to our policy terms and conditions.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      PrimaryButton(
                          label: 'BOOK APPOINTMENT',
                          onPressed: _submit,
                          loading: _busy,
                          color: const Color(0xFFCE2E2E),
                          height: 54),
                    ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
