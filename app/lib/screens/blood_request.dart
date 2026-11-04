import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api.dart';
import '../core/session.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import 'my_requests.dart';

const _groups = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];

class BloodRequestTab extends StatefulWidget {
  final VoidCallback onMenu;
  const BloodRequestTab({super.key, required this.onMenu});
  @override
  State<BloodRequestTab> createState() => _BloodRequestTabState();
}

class _BloodRequestTabState extends State<BloodRequestTab> with FormErrors {
  final _form = GlobalKey<FormState>();
  final _patient = TextEditingController();
  final _contact = TextEditingController();
  final _phone = TextEditingController();
  final _hospital = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _notes = TextEditingController();
  String? _group;
  bool _groupErr = false;
  int _units = 1;
  String _urgency = 'emergency';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _prefill();
  }

  void _prefill() {
    final u = context.read<AppState>().user;
    _contact.text = u?.fullName ?? '';
    _phone.text = u?.phone ?? '';
  }

  @override
  void dispose() {
    for (final c in [
      _patient,
      _contact,
      _phone,
      _hospital,
      _address,
      _city,
      _notes
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final valid = _form.currentState!.validate();
    if (_group == null) setState(() => _groupErr = true);
    if (!valid || _group == null) {
      toast(context, 'Please complete the highlighted fields.', error: true);
      return;
    }
    final api = context.read<AppState>().api;
    setState(() => _busy = true);
    try {
      final r = await api.createBloodRequest({
        'patientName': _patient.text.trim(),
        'contactPerson': _contact.text.trim(),
        'contactNumber': _phone.text.trim(),
        'bloodGroup': _group,
        'units': _units,
        'hospital':
            _hospital.text.trim().isEmpty ? null : _hospital.text.trim(),
        'address': _address.text.trim(),
        'city': _city.text.trim(),
        'urgency': _urgency,
        'notes': _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      });
      if (!mounted) return;
      _clear();
      final track = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          icon: const Icon(Icons.check_circle_rounded,
              color: Color(0xFF2E7D32), size: 52),
          title: const Text('Request sent',
              style: TextStyle(fontWeight: FontWeight.w800)),
          content: Text(
              'Your request for ${r.units} unit${r.units == 1 ? '' : 's'} of ${r.bloodGroup} blood is now open. Donors will be alerted through SMS Notifications.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(c, true),
                child: const Text('Track request')),
            FilledButton(
                style: FilledButton.styleFrom(backgroundColor: C.deepRed),
                onPressed: () => Navigator.pop(c, false),
                child: const Text('Done')),
          ],
        ),
      );
      if (track == true && mounted) {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const MyRequestsScreen(initialTab: 1)));
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => applyApiError(e));
      toast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _clear() {
    setState(() {
      for (final c in [_patient, _hospital, _address, _city, _notes]) {
        c.clear();
      }
      _group = null;
      _groupErr = false;
      _units = 1;
      _urgency = 'emergency';
      srv.clear();
    });
    _form.currentState?.reset();
    _prefill();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.deepRed,
      appBar: redAppBar(context, 'ADD BLOOD REQUEST',
          color: C.deepRed,
          back: false,
          onMenu: widget.onMenu,
          actions: [
            IconButton(
              tooltip: 'My requests',
              icon: const Icon(Icons.history_rounded),
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const MyRequestsScreen(initialTab: 1))),
            ),
          ]),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 24),
          child: Form(
            key: _form,
            child: Column(children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20)),
                child: const Text(
                  'Please ensure that you enter only valid information. If the information is not authentic, it will be removed.',
                  style: TextStyle(
                      fontSize: 15.5, color: Color(0xFF504A4A), height: 1.3),
                ),
              ),
              const SizedBox(height: 14),
              WhiteCard(
                title: 'Patient Information',
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppTextField(
                          hint: 'Patient Name',
                          controller: _patient,
                          capitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          validator: V.minLen('Patient name', 2),
                          serverError: srv['patientName'],
                          onChanged: (_) => clearErr('patientName')),
                      const SizedBox(height: 12),
                      AppTextField(
                          hint: 'Contact Person',
                          controller: _contact,
                          capitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          validator: V.minLen('Contact person', 2),
                          serverError: srv['contactPerson'],
                          onChanged: (_) => clearErr('contactPerson')),
                      const SizedBox(height: 12),
                      AppTextField(
                          hint: 'Contact Number',
                          controller: _phone,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          validator: V.phone(label: 'Contact number'),
                          serverError: srv['contactNumber'],
                          onChanged: (_) => clearErr('contactNumber')),
                      const SizedBox(height: 18),
                      const Text('Select Blood Group',
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Colors.black)),
                      const SizedBox(height: 10),
                      GridView.count(
                        crossAxisCount: 4,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 1.2,
                        children: [
                          for (final g in _groups)
                            _GroupChip(
                                label: g,
                                selected: _group == g,
                                onTap: () => setState(() {
                                      _group = g;
                                      _groupErr = false;
                                    })),
                        ],
                      ),
                      if (_groupErr || srv['bloodGroup'] != null)
                        Padding(
                            padding: const EdgeInsets.only(top: 8, left: 4),
                            child: Text(
                                srv['bloodGroup'] ?? 'Select a blood group',
                                style: const TextStyle(
                                    color: Color(0xFFB3261E),
                                    fontWeight: FontWeight.w600))),
                      const SizedBox(height: 18),
                      Row(children: [
                        const Expanded(
                            child: Text('Units needed',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black))),
                        IconButton.filledTonal(
                            tooltip: 'Fewer',
                            onPressed: _units > 1
                                ? () => setState(() => _units--)
                                : null,
                            icon: const Icon(Icons.remove_rounded)),
                        SizedBox(
                            width: 40,
                            child: Text('$_units',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800))),
                        IconButton.filledTonal(
                            tooltip: 'More',
                            onPressed: _units < 10
                                ? () => setState(() => _units++)
                                : null,
                            icon: const Icon(Icons.add_rounded)),
                      ]),
                      const SizedBox(height: 10),
                      const Text('How urgent?',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.black)),
                      const SizedBox(height: 8),
                      Wrap(spacing: 8, children: [
                        for (final u in const [
                          ('emergency', 'Emergency'),
                          ('urgent', 'Urgent'),
                          ('scheduled', 'Scheduled')
                        ])
                          ChoiceChip(
                            label: Text(u.$2,
                                style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: _urgency == u.$1
                                        ? Colors.white
                                        : Colors.black)),
                            selected: _urgency == u.$1,
                            selectedColor: C.deepRed,
                            checkmarkColor: Colors.white,
                            backgroundColor: C.soft,
                            onSelected: (_) => setState(() => _urgency = u.$1),
                          ),
                      ]),
                    ]),
              ),
              const SizedBox(height: 14),
              WhiteCard(
                title: 'Location Details',
                child: Column(children: [
                  AppTextField(
                      hint: 'Hospital (optional)',
                      controller: _hospital,
                      capitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next),
                  const SizedBox(height: 12),
                  AppTextField(
                      hint: 'Address',
                      controller: _address,
                      textInputAction: TextInputAction.next,
                      validator: V.minLen('Address', 3),
                      serverError: srv['address'],
                      onChanged: (_) => clearErr('address')),
                  const SizedBox(height: 12),
                  AppTextField(
                      hint: 'City',
                      controller: _city,
                      capitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      validator: V.minLen('City', 2),
                      serverError: srv['city'],
                      onChanged: (_) => clearErr('city')),
                  const SizedBox(height: 12),
                  AppTextField(
                      hint: 'Notes for donors (optional)',
                      controller: _notes,
                      maxLines: 3,
                      maxLength: 500,
                      textInputAction: TextInputAction.newline),
                ]),
              ),
              const SizedBox(height: 18),
              PrimaryButton(
                  label: 'Submit Request',
                  onPressed: _submit,
                  loading: _busy,
                  color: C.darkRed),
            ]),
          ),
        ),
      ),
    );
  }
}

class _GroupChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _GroupChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: selected,
        label: 'Blood group $label',
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? C.deepRed : const Color(0xFFF0EEEE),
              borderRadius: BorderRadius.circular(16),
              boxShadow: selected
                  ? [
                      BoxShadow(
                          color: C.opacity(C.deepRed, .35),
                          blurRadius: 8,
                          offset: const Offset(0, 3))
                    ]
                  : const [
                      BoxShadow(
                          color: Color(0x22000000),
                          blurRadius: 4,
                          offset: Offset(0, 2))
                    ],
            ),
            child: Text(label,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: selected ? Colors.white : Colors.black)),
          ),
        ),
      );
}
